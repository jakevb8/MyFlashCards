Feature: Flashcard Management
  As a user
  I want to add and manage flashcards within a deck
  So that I can create study material

  Scenario: Cards load automatically when opening a deck
    Given I have a deck named "French Words" with 3 cards
    When I open the deck
    Then I should see all 3 cards immediately

  Scenario: Add a flashcard to a deck
    Given I have a deck named "French Words"
    When I add a card with front "Bonjour" and back "Hello"
    Then I should see "Bonjour" in the card list

  Scenario: Edit a flashcard
    Given I have a card with front "Hola" and back "Hi"
    When I edit the card to have front "Hola" and back "Hello"
    Then the card should show "Hello" as the back

  Scenario: Delete a flashcard via swipe
    Given I have a card with front "Delete Me" in the deck
    When I swipe left on the card
    And I tap "Delete"
    Then I should not see "Delete Me" in the card list

  Scenario: Swipe hint is visible when cards exist
    Given I have at least one card in a deck
    When I am on the card list screen
    Then I should see the hint "Swipe left on a card to edit or delete"

  Scenario: Cannot add a card without front text
    Given I am adding a card to a deck
    When I submit with an empty front
    Then I should see a validation error

  Scenario: Cannot add a card without back text
    Given I am adding a card to a deck
    When I submit with an empty back
    Then I should see a validation error

  Scenario: Flashcard ID is preserved when created programmatically
    Given a flashcard is created with a pre-assigned ID and deckId
    Then the flashcard stored in the repository should have that same ID and deckId
    And it should not be replaced with a new UUID
