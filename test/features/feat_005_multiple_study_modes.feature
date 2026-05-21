Feature: Multiple Study Modes (FEAT-005)
  As a learner I want to choose how cards are presented so I can engage
  different recall pathways.

  Scenario: Mode picker appears before study starts
    Given I am on the flashcard list screen with at least one card
    When I tap the Study button
    Then a mode picker sheet appears with Flashcard Flip, Multiple Choice, and Type the Answer options

  Scenario: Flashcard Flip launches the classic flip session
    Given I open the mode picker
    When I select Flashcard Flip and tap Start Session
    Then I see a flippable flashcard with Again / Hard / Good / Easy rating buttons

  Scenario: Multiple Choice shows four answer options
    Given I open the mode picker
    When I select Multiple Choice and tap Start Session
    Then I see the card front and four answer buttons

  Scenario: Correct multiple-choice answer auto-advances after feedback
    Given I am in a Multiple Choice session
    When I tap the correct answer
    Then the correct option highlights green and the session advances automatically

  Scenario: Type the Answer shows a text field
    Given I open the mode picker
    When I select Type the Answer and tap Start Session
    Then I see the card front and a text input field with a Check button

  Scenario: Correct typed answer shows success feedback and Continue button
    Given I am in a Type the Answer session
    When I type the correct answer and tap Check
    Then I see a green "Correct!" banner and a Continue button

  Scenario: Wrong typed answer shows the correct answer
    Given I am in a Type the Answer session
    When I type a wrong answer and tap Check
    Then I see a red "Incorrect" banner with the correct answer displayed

  Scenario: Close-enough matching accepts minor typos
    Given I am in a Type the Answer session with tolerant matching enabled
    When I type an answer with a single character typo
    Then the answer is accepted as correct
