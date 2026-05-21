Feature: Spaced Repetition (SM-2)
  As a learner
  I want cards to be scheduled based on how well I know them
  So that I spend more time on difficult cards and less on easy ones

  Scenario: New cards are always shown in a study session
    Given I have a deck with 3 new cards (never reviewed)
    When I start a study session
    Then all 3 cards appear in the session

  Scenario: Cards with a future review date are excluded
    Given I have a deck with cards that are not yet due
    When I start a study session
    Then I see a "You're all caught up!" message

  Scenario: Rating a card as Easy defers it by 1 day
    Given I am studying a new card
    When I flip the card and tap "Easy"
    Then the card's next review date is set to tomorrow
    And I advance to the next card automatically

  Scenario: Rating a card as Again resets it to tomorrow
    Given I am studying a card I have reviewed before
    When I flip the card and tap "Again"
    Then the card's interval resets to 1 day and the repetition count resets to 0

  Scenario: Rating buttons appear only after flipping
    Given I am on a card showing the front
    When I have not yet flipped the card
    Then I see a "Tap card to flip" hint and no rating buttons

  Scenario: Session completes after all due cards are rated
    Given I have a session with 2 due cards
    When I rate each card
    Then I see the session complete screen
