import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_flash_cards/blocs/import_export/import_export_bloc.dart';
import 'package:my_flash_cards/blocs/import_export/import_export_event.dart';
import 'package:my_flash_cards/blocs/import_export/import_export_state.dart';
import 'package:my_flash_cards/models/deck.dart';
import 'package:my_flash_cards/models/flashcard.dart';
import 'package:my_flash_cards/repositories/deck_repository.dart';
import 'package:my_flash_cards/repositories/flashcard_repository.dart';
import 'package:my_flash_cards/services/deck_import_export_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDeckRepository extends Mock implements DeckRepository {}

class MockFlashcardRepository extends Mock implements FlashcardRepository {}

class MockDeckImportExportService extends Mock
    implements DeckImportExportService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Deck makeDeck({String id = 'deck-1', String name = 'Test Deck'}) {
  final now = DateTime(2026, 1, 1);
  return Deck(
    id: id,
    name: name,
    description: '',
    createdAt: now,
    updatedAt: now,
  );
}

Flashcard makeCard({String id = 'card-1', String deckId = 'deck-1'}) {
  final now = DateTime(2026, 1, 1);
  return Flashcard(
    id: id,
    deckId: deckId,
    front: 'Front',
    back: 'Back',
    createdAt: now,
    updatedAt: now,
  );
}

DeckImportExportBundle makeBundle({
  String deckName = 'Test Deck',
  List<Flashcard>? cards,
}) => DeckImportExportBundle(
  deck: makeDeck(name: deckName),
  cards: cards ?? [makeCard()],
);

void main() {
  setUpAll(() {
    // mocktail requires fallback values for any() matchers on custom types.
    registerFallbackValue(
      Deck(
        id: '',
        name: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    registerFallbackValue(
      Flashcard(
        id: '',
        deckId: '',
        front: '',
        back: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  late MockDeckRepository deckRepo;
  late MockFlashcardRepository cardRepo;
  late MockDeckImportExportService service;

  setUp(() {
    deckRepo = MockDeckRepository();
    cardRepo = MockFlashcardRepository();
    service = MockDeckImportExportService();

    // Default stubs.
    when(() => deckRepo.getDecks()).thenAnswer((_) async => []);
    when(() => deckRepo.addDeck(any())).thenAnswer((_) async {});
    when(() => deckRepo.deleteDeck(any())).thenAnswer((_) async {});
    when(() => cardRepo.addFlashcard(any())).thenAnswer((_) async {});
    when(() => cardRepo.deleteFlashcard(any())).thenAnswer((_) async {});
    when(() => cardRepo.getFlashcards(any())).thenAnswer((_) async => []);
    when(() => service.pickAndParse()).thenAnswer((_) async => null);
    when(
      () => service.exportAndShare(any(), any(), format: any(named: 'format')),
    ).thenAnswer((_) async {});
  });

  ImportExportBloc makeBloc() => ImportExportBloc(
    deckRepository: deckRepo,
    flashcardRepository: cardRepo,
    service: service,
  );

  group('ImportExportBloc', () {
    // --- Import: picker cancelled ---
    blocTest<ImportExportBloc, ImportExportState>(
      'ImportDeckRequested when picker returns null → emits [InProgress, Idle]',
      build: makeBloc,
      act: (b) => b.add(ImportDeckRequested()),
      expect: () => [isA<ImportExportInProgress>(), isA<ImportExportIdle>()],
    );

    // --- Import: no duplicate ---
    blocTest<ImportExportBloc, ImportExportState>(
      'ImportDeckRequested with no duplicate → emits [InProgress, Success, Idle]',
      build: makeBloc,
      setUp: () {
        when(
          () => service.pickAndParse(),
        ).thenAnswer((_) async => makeBundle());
      },
      act: (b) => b.add(ImportDeckRequested()),
      expect: () => [
        isA<ImportExportInProgress>(),
        isA<ImportExportSuccess>(),
        isA<ImportExportIdle>(),
      ],
      verify: (_) {
        verify(() => deckRepo.addDeck(any())).called(1);
        verify(() => cardRepo.addFlashcard(any())).called(1);
      },
    );

    // --- Import: duplicate detected ---
    blocTest<ImportExportBloc, ImportExportState>(
      'ImportDeckRequested when name matches → emits [InProgress, DuplicateDetected]',
      build: makeBloc,
      setUp: () {
        when(
          () => service.pickAndParse(),
        ).thenAnswer((_) async => makeBundle(deckName: 'Test Deck'));
        when(
          () => deckRepo.getDecks(),
        ).thenAnswer((_) async => [makeDeck(name: 'Test Deck')]);
      },
      act: (b) => b.add(ImportDeckRequested()),
      expect: () => [
        isA<ImportExportInProgress>(),
        isA<ImportDuplicateDetected>(),
      ],
    );

    // --- Import: confirm replace ---
    blocTest<ImportExportBloc, ImportExportState>(
      'ImportConfirmReplace deletes old deck+cards then imports → emits [InProgress, Success, Idle]',
      build: makeBloc,
      setUp: () {
        when(
          () => deckRepo.getDecks(),
        ).thenAnswer((_) async => [makeDeck(id: 'old-id', name: 'Test Deck')]);
        when(
          () => cardRepo.getFlashcards('old-id'),
        ).thenAnswer((_) async => [makeCard(id: 'old-card', deckId: 'old-id')]);
      },
      act: (b) => b.add(ImportConfirmReplace(makeBundle())),
      expect: () => [
        isA<ImportExportInProgress>(),
        isA<ImportExportSuccess>(),
        isA<ImportExportIdle>(),
      ],
      verify: (_) {
        verify(() => cardRepo.deleteFlashcard('old-card')).called(1);
        verify(() => deckRepo.deleteDeck('old-id')).called(1);
        verify(() => deckRepo.addDeck(any())).called(1);
        verify(() => cardRepo.addFlashcard(any())).called(1);
      },
    );

    // --- Import: confirm merge ---
    blocTest<ImportExportBloc, ImportExportState>(
      'ImportConfirmMerge skips cards with existing IDs → only inserts new cards',
      build: makeBloc,
      setUp: () {
        // existingDeck already has card-1; bundle has card-1 (skip) + card-2 (new)
        when(
          () => cardRepo.getFlashcards('deck-1'),
        ).thenAnswer((_) async => [makeCard(id: 'card-1')]);
      },
      act: (b) => b.add(
        ImportConfirmMerge(
          bundle: makeBundle(
            cards: [
              makeCard(id: 'card-1'),
              makeCard(id: 'card-2'),
            ],
          ),
          existingDeck: makeDeck(),
        ),
      ),
      expect: () => [
        isA<ImportExportInProgress>(),
        isA<ImportExportSuccess>().having(
          (s) => s.message,
          'shows 1 new card',
          contains('1 new card'),
        ),
        isA<ImportExportIdle>(),
      ],
      verify: (_) {
        // Only card-2 should be added; card-1 already exists.
        verify(() => cardRepo.addFlashcard(any())).called(1);
      },
    );

    // --- Import cancelled ---
    blocTest<ImportExportBloc, ImportExportState>(
      'ImportCancelled → emits [Idle]',
      build: makeBloc,
      act: (b) => b.add(ImportCancelled()),
      expect: () => [isA<ImportExportIdle>()],
    );

    // --- Export success ---
    blocTest<ImportExportBloc, ImportExportState>(
      'ExportDeckRequested success → emits [InProgress, Success, Idle]',
      build: makeBloc,
      act: (b) => b.add(
        ExportDeckRequested(
          deck: makeDeck(),
          cards: [makeCard()],
          format: 'json',
        ),
      ),
      expect: () => [
        isA<ImportExportInProgress>(),
        isA<ImportExportSuccess>(),
        isA<ImportExportIdle>(),
      ],
      verify: (_) {
        verify(
          () => service.exportAndShare(any(), any(), format: 'json'),
        ).called(1);
      },
    );

    // --- Export failure ---
    blocTest<ImportExportBloc, ImportExportState>(
      'ExportDeckRequested when service throws → emits [InProgress, Error, Idle]',
      build: makeBloc,
      setUp: () {
        when(
          () => service.exportAndShare(
            any(),
            any(),
            format: any(named: 'format'),
          ),
        ).thenThrow(Exception('share failed'));
      },
      act: (b) => b.add(
        ExportDeckRequested(
          deck: makeDeck(),
          cards: [makeCard()],
          format: 'csv',
        ),
      ),
      expect: () => [
        isA<ImportExportInProgress>(),
        isA<ImportExportError>(),
        isA<ImportExportIdle>(),
      ],
    );
  });
}
