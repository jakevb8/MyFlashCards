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

  Scenario: Study with deck flipped (back shown first)
    Given I have a deck with cards where front is "cat" and back is "gato"
    When I start a study session with "Study Flipped" 
    Then I should see "gato" as the question on the first card
    And tapping the card should reveal "cat" as the answer

  Scenario: Flip icon in study app bar toggles flip state
    Given I am studying a deck in normal order
    When I tap the flip icon in the app bar
    Then the deck should restart with back shown first
    And the flip icon should be highlighted to indicate flipped mode

  Scenario: Flipped session can also be shuffled
    Given I am studying a flipped deck
    When I tap the shuffle icon
    Then the cards should be shuffled and still show back→front
