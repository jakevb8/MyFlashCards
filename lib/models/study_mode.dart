// Study mode selected by the user before a session begins.
// Each mode presents cards differently but all feed the same SM-2 pipeline.
enum StudyMode {
  /// Classic flashcard flip: see the front, tap to reveal back, then rate.
  flashcard,

  /// Multiple choice: four options (correct + 3 distractors) are shown;
  /// tapping an option auto-rates and advances.
  multipleChoice,

  /// Type the answer: user recalls the answer by typing; case-insensitive
  /// matching, with an optional tolerance for minor typos.
  typeAnswer,
}
