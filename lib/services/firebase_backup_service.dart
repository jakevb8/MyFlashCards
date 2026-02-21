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
  ///
  /// Firebase opens a browser, handles the OAuth exchange with GitHub,
  /// then redirects back to the app via the custom URL scheme configured
  /// in Firebase Console (e.g. `com.myflashcards.app://`).
  /// No client secret is ever stored in the app.
  Future<UserCredential> signInWithGitHub() async {
    final provider = GithubAuthProvider();
    // Request the user:email scope so we can display their email
    provider.addScope('user:email');
    // signInWithProvider opens a secure in-app browser (SFSafariViewController
    // on iOS, Chrome Custom Tab on Android) and handles the full OAuth flow.
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
    final batch = _firestore.batch();

    for (final card in cards) {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('flashcards')
          .doc(card.id);
      batch.set(ref, card.toJson());
    }
    await batch.commit();
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
    return snapshot.docs.map((doc) => Flashcard.fromJson(doc.data())).toList();
  }
}
