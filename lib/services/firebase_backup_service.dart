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
    final batch = _firestore.batch();
    for (final deck in decks) {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('decks')
          .doc(deck.id);
      batch.set(ref, deck.toJson());
    }
    await batch.commit();
  }

  Future<void> backupFlashcards(List<Flashcard> cards) async {
    if (!isSignedIn) throw Exception('Not signed in');
    final uid = currentUser!.uid;
    // Firestore batches are limited to 500 writes; chunk if necessary.
    const chunkSize = 400;
    for (var i = 0; i < cards.length; i += chunkSize) {
      final chunk = cards.sublist(
        i,
        i + chunkSize > cards.length ? cards.length : i + chunkSize,
      );
      final batch = _firestore.batch();
      for (final card in chunk) {
        final ref = _firestore
            .collection('users')
            .doc(uid)
            .collection('flashcards')
            .doc(card.id);
        batch.set(ref, card.toJson()); // includes starCount & archived
      }
      await batch.commit();
    }
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
