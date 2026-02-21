import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/models/deck.dart';

void main() {
  group('Deck model', () {
    final now = DateTime(2026, 1, 1);

    test('creates a Deck with required fields', () {
      final deck = Deck(
        id: '1',
        name: 'Spanish',
        createdAt: now,
        updatedAt: now,
      );
      expect(deck.id, '1');
      expect(deck.name, 'Spanish');
      expect(deck.description, '');
    });

    test('copyWith returns updated deck', () {
      final deck = Deck(
        id: '1',
        name: 'Spanish',
        createdAt: now,
        updatedAt: now,
      );
      final updated = deck.copyWith(name: 'Advanced Spanish');
      expect(updated.name, 'Advanced Spanish');
      expect(updated.id, deck.id);
    });

    test('serialises to and from JSON', () {
      final deck = Deck(
        id: 'abc',
        name: 'Geography',
        description: 'World capitals',
        createdAt: now,
        updatedAt: now,
      );
      final json = deck.toJson();
      final restored = Deck.fromJson(json);
      expect(restored, deck);
    });

    test('equality holds for identical decks', () {
      final a = Deck(id: '1', name: 'X', createdAt: now, updatedAt: now);
      final b = Deck(id: '1', name: 'X', createdAt: now, updatedAt: now);
      expect(a, equals(b));
    });
  });
}
