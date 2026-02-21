import '../models/deck.dart';

abstract class DeckRepository {
  Future<List<Deck>> getDecks();
  Future<Deck> getDeck(String id);
  Future<void> addDeck(Deck deck);
  Future<void> updateDeck(Deck deck);
  Future<void> deleteDeck(String id);
}
