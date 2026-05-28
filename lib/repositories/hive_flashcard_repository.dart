import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/flashcard.dart';
import 'flashcard_repository.dart';

class HiveFlashcardRepository implements FlashcardRepository {
  static const String _boxName = 'flashcards';
  final _uuid = const Uuid();

  Box<Flashcard> get _box => Hive.box<Flashcard>(_boxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Flashcard>(_boxName);
    }
  }

  @override
  Future<List<Flashcard>> getFlashcards(String deckId) async {
    return _box.values.where((c) => c.deckId == deckId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Returns cards from multiple decks in one pass over the Hive box, avoiding
  /// repeated full scans when launching a bundled multi-deck study session.
  @override
  Future<List<Flashcard>> getFlashcardsByDecks(List<String> deckIds) async {
    final idSet = deckIds.toSet();
    return _box.values.where((c) => idSet.contains(c.deckId)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Returns every flashcard across all decks — used by the backup service.
  Future<List<Flashcard>> getAllFlashcards() async {
    return _box.values.toList();
  }

  @override
  /// Returns the count of non-archived cards that are currently due for review.
  ///
  /// A card is due when [Flashcard.nextReviewAt] is null (new, never reviewed)
  /// or is not after [DateTime.now()]. Used by the notification service to
  /// populate the reminder body without loading all card data into memory.
  Future<int> countDueCards() async {
    final now = DateTime.now();
    return _box.values
        .where(
          (c) =>
              !c.archived &&
              (c.nextReviewAt == null || !c.nextReviewAt!.isAfter(now)),
        )
        .length;
  }

  @override
  Future<Flashcard> getFlashcard(String id) async {
    return _box.values.firstWhere((c) => c.id == id);
  }

  @override
  Future<void> addFlashcard(Flashcard flashcard) async {
    final card = flashcard.id.isEmpty
        ? flashcard.copyWith(id: _uuid.v4())
        : flashcard;
    await _box.put(card.id, card);
  }

  @override
  Future<void> updateFlashcard(Flashcard flashcard) async {
    await _box.put(flashcard.id, flashcard.copyWith(updatedAt: DateTime.now()));
  }

  @override
  Future<void> deleteFlashcard(String id) async {
    await _box.delete(id);
  }

  /// Delete all flashcards from local storage (used before a full restore).
  Future<void> clearAll() async {
    await _box.clear();
  }
}
