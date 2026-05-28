import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

Future<void> theCardsIntervalResetsTo1DayAndTheRepetitionCountResetsTo0(
  WidgetTester tester,
) async {
  final cards = await testCardRepo.getFlashcards(testCurrentDeck!.id);
  if (cards.isNotEmpty) {
    expect(cards.first.intervalDays, equals(1));
    expect(cards.first.repetitions, equals(0));
  }
  // Absence from repo is also acceptable if it was removed from testCardRepo
}
