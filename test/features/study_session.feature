Feature: Study Session
  As a user
  I want to study flashcards in a session
  So that I can review and memorise them

  Scenario: Study cards in order
    Given I have a deck with 3 cards
    When I start a study session in order
    Then I should see the first card's front

  Scenario: Flip a card
    Given I am studying a card showing the front
    When I tap the card
    Then I should see the card's back

  Scenario: Navigate to next card
    Given I am on card 1 of 3 in a study session
    When I tap "Next"
    Then I should be on card 2 of 3

  Scenario: Navigate to previous card
    Given I am on card 2 of 3 in a study session
    When I tap "Previous"
    Then I should be on card 1 of 3

  Scenario: Complete a session
    Given I am on the last card in a study session
    When I tap "Finish"
    Then I should see the session complete screen

  Scenario: Shuffle cards
    Given I have a deck with 5 cards
    When I start a study session with shuffle enabled
    Then the cards should be in a different order

  Scenario: Restart a session
    Given I have finished a study session
    When I tap "Restart"
    Then I should be back on card 1
