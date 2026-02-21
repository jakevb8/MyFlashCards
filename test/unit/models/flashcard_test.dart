import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/models/flashcard.dart';

void main() {
  group('Flashcard model', () {
    final now = DateTime(2026, 1, 1);

    test('creates a Flashcard with required fields', () {
      final card = Flashcard(
        id: '1',
        deckId: 'deck1',
        front: 'What is 2+2?',
        back: '4',
        createdAt: now,
        updatedAt: now,
      );
      expect(card.front, 'What is 2+2?');
      expect(card.back, '4');
      expect(card.deckId, 'deck1');
    });

    test('copyWith returns updated flashcard', () {
      final card = Flashcard(
        id: '1',
        deckId: 'deck1',
        front: 'Hello',
        back: 'World',
        createdAt: now,
        updatedAt: now,
      );
      final updated = card.copyWith(back: 'Updated');
      expect(updated.back, 'Updated');
      expect(updated.front, card.front);
    });

    test('serialises to and from JSON', () {
      final card = Flashcard(
        id: '42',
        deckId: 'deck99',
        front: 'Bonjour',
        back: 'Hello',
        createdAt: now,
        updatedAt: now,
      );
      final json = card.toJson();
      final restored = Flashcard.fromJson(json);
      expect(restored, card);
    });
  });
}
