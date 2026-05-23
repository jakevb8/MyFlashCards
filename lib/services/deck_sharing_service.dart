// DeckSharingService — publishes a deck to the public /shared_decks/{shareId}
// Firestore collection and builds the deep link the sender shares.
//
// Firestore path: /shared_decks/{shareId}
//   Fields: payload (JSON string), deckName, ownerId, createdAt, expiresAt (ISO
//   strings), schemaVersion (int). TTL is enforced in this service at read time
//   (7 days from publish). Documents are immutable once written.
//
// Deep-link format: myflashcards://deck/{shareId}
//
// This service is stateless — instantiate fresh or share a singleton.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import 'deck_import_export_service.dart';

/// Thrown when a sharing operation cannot be completed.
class DeckSharingException implements Exception {
  final String message;
  const DeckSharingException(this.message);

  @override
  String toString() => 'DeckSharingException: $message';
}

class DeckSharingService {
  // Firebase instances are resolved lazily (inside methods) so constructing
  // this service in tests doesn't require Firebase.initializeApp().
  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final DeckImportExportService _importExport;

  DeckSharingService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DeckImportExportService? importExport,
  }) : _authOverride = auth,
       _firestoreOverride = firestore,
       _importExport = importExport ?? DeckImportExportService();

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Sender path
  // ---------------------------------------------------------------------------

  /// Publishes [deck] and [cards] to Firestore and returns a deep-link string.
  ///
  /// The shared document expires 7 days from now. Expired documents remain in
  /// Firestore but are rejected at read time — see [fetchSharedDeck].
  /// Throws [DeckSharingException] if the user is not signed in or if Firestore
  /// write fails.
  Future<String> publishSharedDeck(Deck deck, List<Flashcard> cards) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const DeckSharingException(
        'You must be signed in to share a deck.',
      );
    }

    final shareId = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(days: 7));

    final payload = _importExport.encodeJson(deck, cards);

    try {
      await _firestore.collection('shared_decks').doc(shareId).set({
        'schemaVersion': 1,
        'payload': payload,
        'deckName': deck.name,
        'ownerId': user.uid,
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw DeckSharingException('Could not publish deck: ${e.message}');
    }

    return buildDeepLink(shareId);
  }

  // ---------------------------------------------------------------------------
  // Receiver path
  // ---------------------------------------------------------------------------

  /// Fetches and deserializes a shared deck by [shareId].
  ///
  /// Returns a [DeckImportExportBundle] ready for import. Throws
  /// [DeckSharingException] if the document does not exist, has expired, or
  /// cannot be parsed.
  Future<DeckImportExportBundle> fetchSharedDeck(String shareId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _firestore.collection('shared_decks').doc(shareId).get();
    } on FirebaseException catch (e) {
      throw DeckSharingException('Could not fetch shared deck: ${e.message}');
    }

    if (!doc.exists || doc.data() == null) {
      throw const DeckSharingException(
        'Shared deck not found. The link may be invalid.',
      );
    }

    final data = doc.data()!;

    // Enforce TTL in the service layer — free tier has no Cloud Functions.
    final expiresAt = DateTime.parse(data['expiresAt'] as String);
    if (DateTime.now().toUtc().isAfter(expiresAt)) {
      throw const DeckSharingException('This share link has expired.');
    }

    try {
      return _importExport.decodeJson(data['payload'] as String);
    } on FormatException catch (e) {
      throw DeckSharingException('Could not parse shared deck: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Builds the deep link for a given [shareId].
  ///
  /// Format: myflashcards://deck/{shareId}
  String buildDeepLink(String shareId) => 'myflashcards://deck/$shareId';
}
