// account_deletion_service.dart
//
// Orchestrates permanent account deletion: wipes all Firestore data owned by
// the current user, deletes the Firebase Auth account, then clears local Hive
// storage and SharedPreferences state.
//
// Why this service exists: account deletion touches three separate systems
// (Firestore, Firebase Auth, Hive, SharedPreferences) and must execute them in
// the right order — remote data first so we can still authenticate while
// deleting, Auth account last. Centralising this sequence here keeps the
// SettingsScreen free of deletion orchestration logic and makes the steps easy
// to test or audit independently.
//
// Critical invariants:
//   - The user must be authenticated before calling deleteAccount(); if not, an
//     Exception is thrown immediately.
//   - Firebase Auth requires a recent sign-in for account deletion. If the
//     session is too old, FirebaseAuthException(code: requires-recent-login) is
//     caught and rethrown as ReauthRequiredException so the UI can give a
//     helpful, actionable error message.
//   - Firestore deletes use batches capped at 400 ops to stay within limits.
//   - Local storage is cleared AFTER the Auth account is deleted so that if
//     Auth deletion fails we have not lost the user's local data.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/hive_deck_repository.dart';
import '../repositories/hive_flashcard_repository.dart';

/// Thrown when Firebase Auth requires the user to reauthenticate before deleting
/// their account. The caller should present a message directing the user to sign
/// out and sign back in before retrying.
class ReauthRequiredException implements Exception {
  const ReauthRequiredException();

  @override
  String toString() => 'ReauthRequiredException: recent login required';
}

/// Maximum Firestore operations per batch. Firestore supports 500 but we cap at
/// 400 to leave headroom for any hidden bookkeeping writes.
const int _kBatchSize = 400;

/// SharedPreferences key for the last auto-backup timestamp — must be cleared
/// on account deletion so the next sign-in starts fresh.
const String _kLastAutoBackupKey = 'auto_backup_last_at';

class AccountDeletionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Permanently deletes the current user's account and all associated data.
  ///
  /// Order of operations:
  ///   1. Validate the user is signed in.
  ///   2. Delete all Firestore subcollection docs (decks, flashcards, _meta).
  ///   3. Delete the root /users/{uid} document.
  ///   4. Delete the Firebase Auth account — throws [ReauthRequiredException]
  ///      if the session is too old.
  ///   5. Clear Hive local data via [deckRepo] and [cardRepo].
  ///   6. Clear the auto-backup SharedPreferences timestamp.
  ///
  /// Throws [ReauthRequiredException] if the user must sign in again first.
  /// Throws [Exception] if no user is currently authenticated.
  Future<void> deleteAccount({
    required HiveDeckRepository deckRepo,
    required HiveFlashcardRepository cardRepo,
  }) async {
    // Step 1: Guard — we need the UID before touching anything.
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('deleteAccount called while no user is signed in');
    }
    final uid = user.uid;

    // Step 2: Delete all docs in /users/{uid}/decks/ using batches.
    await _deleteCollection(
      _firestore.collection('users').doc(uid).collection('decks'),
    );

    // Step 3: Delete all docs in /users/{uid}/flashcards/ using batches.
    await _deleteCollection(
      _firestore.collection('users').doc(uid).collection('flashcards'),
    );

    // Step 4: Delete all docs in /users/{uid}/_meta/ (e.g. the backup doc).
    await _deleteCollection(
      _firestore.collection('users').doc(uid).collection('_meta'),
    );

    // Step 5: Delete the root /users/{uid} document (holds theme settings).
    await _firestore.collection('users').doc(uid).delete();

    // Step 6: Delete the Firebase Auth account. Firebase requires the session
    // to be recent; if not, it throws requires-recent-login which we translate
    // to a user-facing ReauthRequiredException.
    try {
      await _auth.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const ReauthRequiredException();
      }
      rethrow;
    }

    // Step 7: Clear local Hive data. We do this after Auth deletion succeeds so
    // that if Auth deletion fails (e.g. requires reauth) the user still has
    // their local data intact.
    await deckRepo.clearAll();
    await cardRepo.clearAll();

    // Step 8: Clear the auto-backup timestamp so the next sign-in starts fresh
    // and does not believe a previous user's backup belongs to the new session.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastAutoBackupKey);
  }

  /// Deletes every document in [collection] using batches of [_kBatchSize].
  ///
  /// Firestore does not support deleting a collection in a single operation, so
  /// we page through the docs 400 at a time and commit each batch. This is
  /// sequential (not concurrent) to avoid hammering the Firestore quota.
  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    // Fetch all doc references — for typical user data (hundreds of cards) this
    // is safe; for massive collections a cursor-paginated loop would be needed.
    final snapshot = await collection.get();
    final refs = snapshot.docs.map((d) => d.reference).toList();

    for (var i = 0; i < refs.length; i += _kBatchSize) {
      final chunk = refs.sublist(i, (i + _kBatchSize).clamp(0, refs.length));
      final batch = _firestore.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
