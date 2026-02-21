// ─── FUTURE IMPLEMENTATION — not active yet ─────────────────────────────────
//
// FirebaseFunctionGeneratorService calls a Firebase Cloud Function to generate
// flashcards. The function holds the Gemini API key in Secret Manager so the
// key never touches the app binary — safe for public distribution.
//
// ─── How to activate ────────────────────────────────────────────────────────
//
// Prerequisites:
//   1. Upgrade Firebase project to the Blaze (pay-as-you-go) plan.
//      Free tier thresholds still apply — no charge at normal personal usage.
//   2. Run: flutter pub add cloud_functions
//   3. Deploy the Cloud Function (see functions/index.js in the project root).
//
// Code change (one line in ai_generate_screen.dart):
//   Change:
//     final CardGeneratorService _service = GeminiDirectService(_kGeminiApiKey);
//   To:
//     final CardGeneratorService _service = FirebaseFunctionGeneratorService();
//
//   Then remove the --dart-define=GEMINI_API_KEY run argument entirely.
//
// ─── Uncomment after running `flutter pub add cloud_functions` ───────────────
//
// import 'package:cloud_functions/cloud_functions.dart';
// import 'card_generator_service.dart';
//
// export 'card_generator_service.dart' show CardSuggestion, CardGeneratorService;
//
// class FirebaseFunctionGeneratorService implements CardGeneratorService {
//   final _functions = FirebaseFunctions.instance;
//
//   @override
//   Future<List<CardSuggestion>> generateFromTopic(String topic) =>
//       _call({'type': 'topic', 'topic': topic});
//
//   @override
//   Future<List<CardSuggestion>> generateFromText(String documentText) =>
//       _call({'type': 'text', 'text': documentText});
//
//   Future<List<CardSuggestion>> _call(Map<String, dynamic> data) async {
//     final result = await _functions
//         .httpsCallable('generateCards')
//         .call<List<dynamic>>(data);
//
//     return (result.data as List<dynamic>)
//         .cast<Map<String, dynamic>>()
//         .map((e) => CardSuggestion(
//               front: e['front'] as String,
//               back: e['back'] as String,
//             ))
//         .toList();
//   }
// }
