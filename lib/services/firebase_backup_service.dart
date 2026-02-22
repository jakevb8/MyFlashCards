import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

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

  // ── Backup ──────────────────────────────────────────────────────────────────

  Future<void> backupDecks(List<Deck> decks) async {
    if (!isSignedIn) throw Exception('Not signed in');
    final uid = currentUser!.uid;
    final col = _firestore.collection('users').doc(uid).collection('decks');

    // Fetch existing doc IDs so we can delete removed decks.
    final existing = await col.get();
    final localIds = decks.map((d) => d.id).toSet();
    final toDelete = existing.docs
        .where((doc) => !localIds.contains(doc.id))
        .map((doc) => doc.reference)
        .toList();

    // Batch all deletes + upserts (≤400 per batch).
    final allOps = <Future<void>>[];
    const chunkSize = 400;

    // Process deletes in chunks.
    for (var i = 0; i < toDelete.length; i += chunkSize) {
      final chunk = toDelete.sublist(
        i,
        (i + chunkSize).clamp(0, toDelete.length),
      );
      final batch = _firestore.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      allOps.add(batch.commit());
    }

    // Process upserts in chunks.
    for (var i = 0; i < decks.length; i += chunkSize) {
      final chunk = decks.sublist(
        i,
        (i + chunkSize).clamp(0, decks.length),
      );
      final batch = _firestore.batch();
      for (final deck in chunk) {
        batch.set(col.doc(deck.id), deck.toJson());
      }
      allOps.add(batch.commit());
    }

    await Future.wait(allOps);
  }

  Future<void> backupFlashcards(List<Flashcard> cards) async {
    if (!isSignedIn) throw Exception('Not signed in');
    final uid = currentUser!.uid;
    final col = _firestore
        .collection('users')
        .doc(uid)
        .collection('flashcards');

    // Fetch existing doc IDs so we can delete removed cards.
    final existing = await col.get();
    final localIds = cards.map((c) => c.id).toSet();
    final toDelete = existing.docs
        .where((doc) => !localIds.contains(doc.id))
        .map((doc) => doc.reference)
        .toList();

    const chunkSize = 400;
    final allOps = <Future<void>>[];

    // Deletes in chunks.
    for (var i = 0; i < toDelete.length; i += chunkSize) {
      final chunk = toDelete.sublist(
        i,
        (i + chunkSize).clamp(0, toDelete.length),
      );
      final batch = _firestore.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      allOps.add(batch.commit());
    }

    // Upserts in chunks (includes starCount & archived via toJson).
    for (var i = 0; i < cards.length; i += chunkSize) {
      final chunk = cards.sublist(
        i,
        (i + chunkSize).clamp(0, cards.length),
      );
      final batch = _firestore.batch();
      for (final card in chunk) {
        batch.set(col.doc(card.id), card.toJson());
      }
      allOps.add(batch.commit());
    }

    await Future.wait(allOps);
  }

  /// Back up theme settings (themeType index, themeMode index, isKidsMode).
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
    return snapshot.docs.map((doc) => Deck.fromJson(doc.data())).toList();
  }

  Future<List<Flashcard>> restoreFlashcards() async {
    if (!isSignedIn) throw Exception('Not signed in');
    final uid = currentUser!.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('flashcards')
        .get();
    return snapshot.docs
        .map((doc) => Flashcard.fromJson(doc.data()))
        .toList();
  }

  /// Restore theme settings from Firestore.
  /// Returns a map with keys: themeTypeIndex, themeModeIndex, isKidsMode.
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
}
