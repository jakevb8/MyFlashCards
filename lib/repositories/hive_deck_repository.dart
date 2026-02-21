import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/deck.dart';
import 'deck_repository.dart';

class HiveDeckRepository implements DeckRepository {
  static const String _boxName = 'decks';
  final _uuid = const Uuid();

  Box<Deck> get _box => Hive.box<Deck>(_boxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Deck>(_boxName);
    }
  }

  @override
  Future<List<Deck>> getDecks() async {
    return _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<Deck> getDeck(String id) async {
    final deck = _box.values.firstWhere((d) => d.id == id);
    return deck;
  }

  @override
  Future<void> addDeck(Deck deck) async {
    final deckWithId = deck.id.isEmpty ? deck.copyWith(id: _uuid.v4()) : deck;
    await _box.put(deckWithId.id, deckWithId);
  }

  @override
  Future<void> updateDeck(Deck deck) async {
    await _box.put(deck.id, deck.copyWith(updatedAt: DateTime.now()));
  }

  @override
  Future<void> deleteDeck(String id) async {
    await _box.delete(id);
  }
}
