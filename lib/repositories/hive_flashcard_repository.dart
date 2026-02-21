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
}
