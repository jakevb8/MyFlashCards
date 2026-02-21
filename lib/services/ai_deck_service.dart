import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

/// A single card suggestion returned by the AI before the user saves the deck.
class CardSuggestion {
  final String front;
  final String back;
  CardSuggestion({required this.front, required this.back});
}

class AiDeckService {
  AiDeckService(this._apiKey);

  final String _apiKey;

  GenerativeModel get _model => GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.7,
        ),
      );

  /// Generate flashcard suggestions from a plain-text topic description.
  Future<List<CardSuggestion>> generateFromTopic(String topic) async {
    final prompt = '''
You are a flashcard creator. Generate exactly 15 flashcard pairs for the following topic.
Each card has a "front" (the question or prompt) and a "back" (the answer).
Return ONLY a valid JSON array with this exact shape:
[{"front": "...", "back": "..."}, ...]

Topic: $topic
''';
    return _generate(prompt);
  }

  /// Generate flashcard suggestions from document text (PDF/txt content).
  Future<List<CardSuggestion>> generateFromText(String documentText) async {
    // Trim to ~8000 chars to stay well within token limits on free tier
    final trimmed = documentText.length > 8000
        ? documentText.substring(0, 8000)
        : documentText;

    final prompt = '''
You are a flashcard creator. Read the following document and extract up to 20 
key concepts, facts, vocabulary words, or important ideas. 
For each one, create a flashcard with a "front" (question or term) and "back" (answer or definition).
Return ONLY a valid JSON array with this exact shape:
[{"front": "...", "back": "..."}, ...]

Document:
$trimmed
''';
    return _generate(prompt);
  }

  Future<List<CardSuggestion>> _generate(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    final raw = response.text;
    if (raw == null || raw.isEmpty) throw Exception('Empty response from AI');

    // Strip markdown code fences if Gemini wraps the JSON
    final json = raw
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    final list = jsonDecode(json) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map((e) => CardSuggestion(
              front: e['front'] as String,
              back: e['back'] as String,
            ))
        .toList();
  }
}
