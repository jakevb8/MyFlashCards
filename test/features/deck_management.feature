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

  Scenario: Delete a deck
    Given I have a deck named "Old Deck"
    When I delete it
    Then I should not see "Old Deck" in my deck list

  Scenario: Cannot create a deck without a name
    Given I have no decks
    When I try to create a deck with an empty name
    Then I should see a validation error
