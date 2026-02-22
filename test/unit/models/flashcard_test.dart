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
      expect(card.starCount, 0);
      expect(card.archived, false);
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

    test('copyWith updates starCount and archived', () {
      final card = Flashcard(
        id: '1',
        deckId: 'deck1',
        front: 'Q',
        back: 'A',
        createdAt: now,
        updatedAt: now,
      );
      final starred = card.copyWith(starCount: 2);
      expect(starred.starCount, 2);
      expect(starred.archived, false);

      final archived = starred.copyWith(starCount: 0, archived: true);
      expect(archived.archived, true);
      expect(archived.starCount, 0);
    });

    test('serialises to and from JSON', () {
      final card = Flashcard(
        id: '42',
        deckId: 'deck99',
        front: 'Bonjour',
        back: 'Hello',
        createdAt: now,
        updatedAt: now,
        starCount: 1,
        archived: false,
      );
      final json = card.toJson();
      expect(json['starCount'], 1);
      expect(json['archived'], false);
      final restored = Flashcard.fromJson(json);
      expect(restored, card);
    });

    test('fromJson defaults starCount and archived when missing', () {
      final json = {
        'id': '1',
        'deckId': 'deck1',
        'front': 'Q',
        'back': 'A',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        // starCount and archived intentionally omitted (old format)
      };
      final card = Flashcard.fromJson(json);
      expect(card.starCount, 0);
      expect(card.archived, false);
    });
  });
}
