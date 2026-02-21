/// Abstract interface for AI flashcard generation.
///
/// Current implementation: [GeminiDirectService] (calls Gemini API directly —
/// suitable for development and the Firebase Spark free plan).
///
/// Production swap: replace with [FirebaseFunctionGeneratorService] once the
/// project is upgraded to the Blaze plan and the Cloud Function is deployed.
/// The [AiGenerateScreen] only depends on this interface — no other changes
/// are needed at that point.
abstract class CardGeneratorService {
  /// Generate flashcard suggestions from a plain-text topic description.
  /// [count] controls how many cards to generate (default 15, range 5–30).
  Future<List<CardSuggestion>> generateFromTopic(String topic, {int count = 15});

  /// Generate flashcard suggestions from the text content of an uploaded file.
  Future<List<CardSuggestion>> generateFromText(String documentText);
}

/// A single card suggestion returned by the AI before the user saves the deck.
class CardSuggestion {
  final String front;
  final String back;
  const CardSuggestion({required this.front, required this.back});
}
