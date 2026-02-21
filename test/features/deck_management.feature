Feature: Deck Management
  As a user
  I want to create, edit, and delete flashcard decks
  So that I can organise my study materials

  Scenario: Create a new deck
    Given I have no decks
    When I create a deck named "Spanish Vocabulary"
    Then I should see "Spanish Vocabulary" in my deck list

  Scenario: Create a deck with description
    Given I have no decks
    When I create a deck named "Geography" with description "World capitals"
    Then I should see "Geography" in my deck list

  Scenario: Edit an existing deck
    Given I have a deck named "Maths"
    When I rename it to "Advanced Maths"
    Then I should see "Advanced Maths" in my deck list
    And I should not see "Maths" in my deck list

  Scenario: Delete a deck via swipe
    Given I have a deck named "Old Deck"
    When I swipe left on the deck
    And I tap "Delete"
    And I confirm the deletion in the dialog
    Then I should not see "Old Deck" in my deck list

  Scenario: Swipe hint is visible when decks exist
    Given I have at least one deck
    When I am on the deck list screen
    Then I should see the hint "Swipe left on a deck to edit or delete"

  Scenario: Cannot create a deck without a name
    Given I have no decks
    When I try to create a deck with an empty name
    Then I should see a validation error

  Scenario: Deck ID is preserved when created programmatically
    Given a deck is created with a pre-assigned ID
    Then the deck stored in the repository should have that same ID
    And it should not be replaced with a new UUID
