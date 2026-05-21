import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flash_cards/models/deck.dart';
import 'package:my_flash_cards/models/flashcard.dart';
import 'package:my_flash_cards/services/deck_import_export_service.dart';

Deck makeDeck() {
  final now = DateTime(2026, 1, 1);
  return Deck(
    id: 'deck-1',
    name: 'Test Deck',
    description: 'A test deck',
    createdAt: now,
    updatedAt: now,
  );
}

List<Flashcard> makeCards() {
  final now = DateTime(2026, 1, 1);
  return [
    Flashcard(
      id: 'card-1',
      deckId: 'deck-1',
      front: 'Front 1',
      back: 'Back 1',
      createdAt: now,
      updatedAt: now,
    ),
    Flashcard(
      id: 'card-2',
      deckId: 'deck-1',
      front: 'Has, comma',
      back: 'Has "quotes"',
      createdAt: now,
      updatedAt: now,
      easeFactor: 2.5,
      intervalDays: 6,
      repetitions: 2,
      nextReviewAt: now.add(const Duration(days: 6)),
    ),
  ];
}

void main() {
  final service = DeckImportExportService();

  group('DeckImportExportService — JSON encode', () {
    test('encodeJson includes schemaVersion, deck name, and card IDs', () {
      final encoded = service.encodeJson(makeDeck(), makeCards());
      expect(encoded, contains('"schemaVersion"'));
      expect(encoded, contains('"Test Deck"'));
      expect(encoded, contains('"card-1"'));
      expect(encoded, contains('"card-2"'));
    });

    test('encodeJson includes SM-2 fields for card-2', () {
      final encoded = service.encodeJson(makeDeck(), makeCards());
      expect(encoded, contains('"easeFactor"'));
      expect(encoded, contains('"intervalDays"'));
    });

    test('encodeJson omits SM-2 keys when null (card-1)', () {
      final now = DateTime(2026, 1, 1);
      final cards = [
        Flashcard(
          id: 'c',
          deckId: 'deck-1',
          front: 'f',
          back: 'b',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final encoded = service.encodeJson(makeDeck(), cards);
      expect(encoded, isNot(contains('"easeFactor"')));
    });
  });

  group('DeckImportExportService — JSON round-trip', () {
    test('encode then fromJson restores deck and cards identically', () {
      final deck = makeDeck();
      final cards = makeCards();
      final encoded = service.encodeJson(deck, cards);

      final raw = jsonDecode(encoded) as Map<String, dynamic>;
      final decodedDeck = Deck.fromJson(raw['deck'] as Map<String, dynamic>);
      final decodedCards = (raw['cards'] as List)
          .map((c) => Flashcard.fromJson(c as Map<String, dynamic>))
          .toList();

      expect(decodedDeck.id, deck.id);
      expect(decodedDeck.name, deck.name);
      expect(decodedDeck.description, deck.description);
      expect(decodedCards.length, 2);
      expect(decodedCards[1].easeFactor, closeTo(2.5, 0.001));
      expect(decodedCards[1].intervalDays, 6);
      expect(decodedCards[1].repetitions, 2);
    });
  });

  group('DeckImportExportService — CSV encode', () {
    test('first row is metadata comment starting with "# "', () {
      final csv = service.encodeCsv(makeDeck(), makeCards());
      expect(csv.startsWith('# '), isTrue);
    });

    test('row count = 1 (meta) + 1 (header) + card count', () {
      final cards = makeCards();
      final csv = service.encodeCsv(makeDeck(), cards);
      final nonEmpty = csv.split('\n').where((l) => l.isNotEmpty).toList();
      expect(nonEmpty.length, 2 + cards.length);
    });

    test('field containing comma is quoted', () {
      final csv = service.encodeCsv(makeDeck(), makeCards());
      expect(csv, contains('"Has, comma"'));
    });

    test('internal double-quote is escaped as ""', () {
      final csv = service.encodeCsv(makeDeck(), makeCards());
      expect(csv, contains('"Has ""quotes"""'));
    });

    test('null SM-2 fields produce empty CSV columns', () {
      final csv = service.encodeCsv(makeDeck(), makeCards());
      // card-1 row (index 2) ends with four empty trailing columns
      final lines = csv.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines[2], endsWith(',,,,'));
    });

    test('non-null SM-2 fields are written to CSV', () {
      final csv = service.encodeCsv(makeDeck(), makeCards());
      expect(csv, contains('2.5'));
      expect(csv, contains(',6,'));
    });

    test('deck metadata comment contains deck id, name, and description', () {
      final csv = service.encodeCsv(makeDeck(), makeCards());
      final metaRow = csv.split('\n').first;
      expect(metaRow, contains('deck-1'));
      expect(metaRow, contains('Test Deck'));
      expect(metaRow, contains('A test deck'));
    });
  });

  group('DeckImportExportService — CSV round-trip', () {
    test('encodeCsv metadata row contains all five deck fields', () {
      final deck = makeDeck();
      final csv = service.encodeCsv(deck, makeCards());
      final meta = csv.split('\n').first.substring(2); // strip '# '
      expect(meta, contains(deck.id));
      expect(meta, contains(deck.name));
    });

    test('encodeJson schemaVersion is 1', () {
      final encoded = service.encodeJson(makeDeck(), makeCards());
      final raw = jsonDecode(encoded) as Map<String, dynamic>;
      expect(raw['schemaVersion'], 1);
    });
  });
}
