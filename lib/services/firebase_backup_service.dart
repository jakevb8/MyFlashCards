// firebase_backup_service.dart
//
// Handles all Firebase Auth operations and Firestore backup/restore for decks,
// flashcards, and theme settings.
//
// Key invariants:
//   - Every operation verifies isSignedIn and uses currentUser!.uid — never a
//     client-supplied ID.
//   - Incremental backup: only records whose local updatedAt is newer than the
//     remote copy are written, cutting Firestore write costs on unchanged data.
//   - backupAll() is the single entry point for both manual and auto-backup; it
//     writes a /users/{uid}/_meta/backup document on success so the UI can
//     show "last backed up X ago".
//   - schemaVersion is stamped on every backed-up document so future restores
//     can detect incompatible payloads and throw BackupSchemaException rather
//     than silently corrupting data.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

// Increment when the shape of deck/flashcard documents changes in a way that
// would break deserialization on older builds.
const int _kSchemaVersion = 1;

/// Thrown during restore when the remote backup was written by a newer app
/// version. The user must update the app before restoring.
class BackupSchemaException implements Exception {
  final int remoteVersion;
  const BackupSchemaException(this.remoteVersion);
  @override
  String toString() =>
      'BackupSchemaException: remote backup uses schema v$remoteVersion, '
      'this app understands up to v$_kSchemaVersion. Please update the app.';
}

/// Metadata written to Firestore after every successful backup run.
/// Stored at /users/{uid}/_meta/backup — separate from user data collections.
class BackupMeta {
  final DateTime lastBackupAt;
  final int deckCount;
  final int cardCount;
  final int schemaVersion;

  const BackupMeta({
    required this.lastBackupAt,
    required this.deckCount,
    required this.cardCount,
    required this.schemaVersion,
  });

  factory BackupMeta.fromMap(Map<String, dynamic> map) => BackupMeta(
    lastBackupAt: DateTime.parse(map['lastBackupAt'] as String).toLocal(),
    deckCount: map['deckCount'] as int? ?? 0,
    cardCount: map['cardCount'] as int? ?? 0,
    schemaVersion: map['schemaVersion'] as int? ?? 1,
  );

  Map<String, dynamic> toMap() => {
    'lastBackupAt': lastBackupAt.toUtc().toIso8601String(),
    'deckCount': deckCount,
    'cardCount': cardCount,
    'schemaVersion': schemaVersion,
  };
}

class FirebaseBackupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> registerWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  /// Sign in with GitHub using Firebase's built-in OAuth flow.
  Future<UserCredential> signInWithGitHub() async {
    final provider = GithubAuthProvider();
    provider.addScope('user:email');
    return _auth.signInWithProvider(provider);
  }

  Future<void> signOut() => _auth.signOut();

  // ── Meta ────────────────────────────────────────────────────────────────────

  /// Reads the last-backup metadata from Firestore.
  /// Returns null if the user has never successfully backed up.
  Future<BackupMeta?> readMeta() async {
    if (!isSignedIn) return null;
    final uid = currentUser!.uid;
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('_meta')
        .doc('backup')
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return BackupMeta.fromMap(doc.data()!);
  }

  /// Writes backup metadata after a successful run. Called only by backupAll().
  Future<void> _writeMeta(int deckCount, int cardCount) async {
    final uid = currentUser!.uid;
    final meta = BackupMeta(
      lastBackupAt: DateTime.now(),
      deckCount: deckCount,
      cardCount: cardCount,
      schemaVersion: _kSchemaVersion,
    );
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('_meta')
        .doc('backup')
        .set(meta.toMap());
  }

  // ── Backup ──────────────────────────────────────────────────────────────────

  /// Single entry point for backup — backs up decks, cards, and theme, then
  /// writes the meta document. Safe to call silently in the background.
  Future<void> backupAll({
    required List<Deck> decks,
    required List<Flashcard> cards,
    required int themeTypeIndex,
    required int themeModeIndex,
    required bool isKidsMode,
  }) async {
    if (!isSignedIn) throw Exception('Not signed in');
    await backupDecks(decks);
    await backupFlashcards(cards);
    await backupThemeSettings(
      themeTypeIndex: themeTypeIndex,
      themeModeIndex: themeModeIndex,
      isKidsMode: isKidsMode,
    );
    await _writeMeta(decks.length, cards.length);
  }

  /// Incrementally backs up decks. Only writes records whose local updatedAt
  /// is newer than the remote copy; still diffs ID sets to handle deletions.
  Future<void> backupDecks(List<Deck> decks) async {
    if (!isSignedIn) throw Exception('Not signed in');
    final uid = currentUser!.uid;
    final col = _firestore.collection('users').doc(uid).collection('decks');

    final existing = await col.get();
    final localIds = decks.map((d) => d.id).toSet();

    // Build remote updatedAt map for incremental comparison.
    final remoteUpdatedAt = <String, DateTime>{};
    for (final doc in existing.docs) {
      final raw = doc.data()['updatedAt'] as String?;
      if (raw != null) remoteUpdatedAt[doc.id] = DateTime.parse(raw);
    }

    final toDelete = existing.docs
        .where((doc) => !localIds.contains(doc.id))
        .map((doc) => doc.reference)
        .toList();

    // Skip records that haven't changed since the last backup.
    final toWrite = decks.where((d) {
      final remote = remoteUpdatedAt[d.id];
      return remote == null || d.updatedAt.isAfter(remote);
    }).toList();

    await _commitBatch(
      toDelete: toDelete,
      toWrite: {
        for (final d in toWrite)
          col.doc(d.id): {...d.toJson(), 'schemaVersion': _kSchemaVersion},
      },
    );
  }

  /// Incrementally backs up flashcards — same logic as [backupDecks].
  Future<void> backupFlashcards(List<Flashcard> cards) async {
    if (!isSignedIn) throw Exception('Not signed in');
    final uid = currentUser!.uid;
    final col =
        _firestore.collection('users').doc(uid).collection('flashcards');

    final existing = await col.get();
    final localIds = cards.map((c) => c.id).toSet();

    final remoteUpdatedAt = <String, DateTime>{};
    for (final doc in existing.docs) {
      final raw = doc.data()['updatedAt'] as String?;
      if (raw != null) remoteUpdatedAt[doc.id] = DateTime.parse(raw);
    }

    final toDelete = existing.docs
        .where((doc) => !localIds.contains(doc.id))
        .map((doc) => doc.reference)
        .toList();

    final toWrite = cards.where((c) {
      final remote = remoteUpdatedAt[c.id];
      return remote == null || c.updatedAt.isAfter(remote);
    }).toList();

    await _commitBatch(
      toDelete: toDelete,
      toWrite: {
        for (final c in toWrite)
          col.doc(c.id): {...c.toJson(), 'schemaVersion': _kSchemaVersion},
      },
    );
  }

  /// Backs up theme settings (themeType index, themeMode index, isKidsMode).
  Future<void> backupThemeSettings({
    required int themeTypeIndex,
    required int themeModeIndex,
    required bool isKidsMode,
  }) async {
    if (!isSignedIn) throw Exception('Not signed in');
    final uid = currentUser!.uid;
    await _firestore.collection('users').doc(uid).set({
      'themeTypeIndex': themeTypeIndex,
      'themeModeIndex': themeModeIndex,
      'isKidsMode': isKidsMode,
    }, SetOptions(merge: true));
  }

  // ── Restore ─────────────────────────────────────────────────────────────────

  Future<List<Deck>> restoreDecks() async {
    if (!isSignedIn) throw Exception('Not signed in');
    final uid = currentUser!.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('decks')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      _checkSchema(data);
      return Deck.fromJson(data);
    }).toList();
  }

  Future<List<Flashcard>> restoreFlashcards() async {
    if (!isSignedIn) throw Exception('Not signed in');
    final uid = currentUser!.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('flashcards')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      _checkSchema(data);
      return Flashcard.fromJson(data);
    }).toList();
  }

  /// Restore theme settings from Firestore.
  /// Returns null if no theme settings have been backed up yet.
  Future<Map<String, dynamic>?> restoreThemeSettings() async {
    if (!isSignedIn) throw Exception('Not signed in');
    final uid = currentUser!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (!data.containsKey('themeTypeIndex')) return null;
    return {
      'themeTypeIndex': data['themeTypeIndex'] as int? ?? 0,
      'themeModeIndex': data['themeModeIndex'] as int? ?? 0,
      'isKidsMode': data['isKidsMode'] as bool? ?? false,
    };
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Throws [BackupSchemaException] if the document was written by a newer app
  /// version. Documents written before schema versioning (no field) are treated
  /// as v1 and are always safe to restore.
  void _checkSchema(Map<String, dynamic> data) {
    final version = data['schemaVersion'] as int?;
    if (version != null && version > _kSchemaVersion) {
      throw BackupSchemaException(version);
    }
  }

  /// Executes deletes then upserts in Firestore batches capped at 400 ops.
  Future<void> _commitBatch({
    required List<DocumentReference<Map<String, dynamic>>> toDelete,
    required Map<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>
        toWrite,
  }) async {
    const chunkSize = 400;
    final allOps = <Future<void>>[];

    for (var i = 0; i < toDelete.length; i += chunkSize) {
      final chunk =
          toDelete.sublist(i, (i + chunkSize).clamp(0, toDelete.length));
      final batch = _firestore.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      allOps.add(batch.commit());
    }

    final writeEntries = toWrite.entries.toList();
    for (var i = 0; i < writeEntries.length; i += chunkSize) {
      final chunk = writeEntries.sublist(
          i, (i + chunkSize).clamp(0, writeEntries.length));
      final batch = _firestore.batch();
      for (final entry in chunk) {
        batch.set(entry.key, entry.value);
      }
      allOps.add(batch.commit());
    }

    await Future.wait(allOps);
  }
}
