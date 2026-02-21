import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_flash_cards/blocs/deck/deck_bloc.dart';
import 'package:my_flash_cards/blocs/deck/deck_event.dart';
import 'package:my_flash_cards/blocs/deck/deck_state.dart';
import 'package:my_flash_cards/models/deck.dart';
import 'package:my_flash_cards/repositories/deck_repository.dart';

class MockDeckRepository extends Mock implements DeckRepository {}

void main() {
  late MockDeckRepository mockRepo;
  final now = DateTime(2026, 1, 1);

  final sampleDeck = Deck(
    id: '1',
    name: 'Test Deck',
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockRepo = MockDeckRepository();
    registerFallbackValue(sampleDeck);
  });

  group('DeckBloc', () {
    blocTest<DeckBloc, DeckState>(
      'emits [DeckLoading, DeckLoaded] when LoadDecks succeeds',
      build: () {
        when(() => mockRepo.getDecks()).thenAnswer((_) async => [sampleDeck]);
        return DeckBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(LoadDecks()),
      expect: () => [
        isA<DeckLoading>(),
        isA<DeckLoaded>().having((s) => s.decks.length, 'deck count', 1),
      ],
    );

    blocTest<DeckBloc, DeckState>(
      'emits [DeckLoading, DeckError] when LoadDecks fails',
      build: () {
        when(() => mockRepo.getDecks()).thenThrow(Exception('Storage error'));
        return DeckBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(LoadDecks()),
      expect: () => [isA<DeckLoading>(), isA<DeckError>()],
    );

    blocTest<DeckBloc, DeckState>(
      'emits DeckLoaded with new deck after AddDeck',
      build: () {
        when(() => mockRepo.addDeck(any())).thenAnswer((_) async {});
        when(() => mockRepo.getDecks()).thenAnswer((_) async => [sampleDeck]);
        return DeckBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(AddDeck(sampleDeck)),
      expect: () => [
        isA<DeckLoaded>().having((s) => s.decks, 'decks', [sampleDeck]),
      ],
    );

    blocTest<DeckBloc, DeckState>(
      'emits DeckLoaded with empty list after DeleteDeck',
      build: () {
        when(() => mockRepo.deleteDeck(any())).thenAnswer((_) async {});
        when(() => mockRepo.getDecks()).thenAnswer((_) async => []);
        return DeckBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(DeleteDeck('1')),
      expect: () => [
        isA<DeckLoaded>().having((s) => s.decks, 'decks', isEmpty),
      ],
    );
  });
}
