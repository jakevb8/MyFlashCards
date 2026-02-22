Feature: AI Deck Generation
  As a user
  I want to generate flashcard decks from a topic or uploaded document
  So that I can quickly create study material without typing each card manually

  Scenario: Generate a deck from a topic prompt
    Given I am on the deck list screen
    When I tap "Generate with AI"
    And I enter the topic "CVC words for a beginning reader"
    And I tap "Generate Cards"
    Then a new deck named "CVC Words For A Beginning Reader" should be created
    And the deck should contain flashcards with words on the front and definitions or examples on the back

  Scenario: Card fronts contain the word itself, not a spelling question
    Given I am on the AI generation screen
    When I tap "Generate Cards" with topic "Animals"
    Then each card front should contain the word or term itself (e.g. "cat")
    And no card front should be phrased as "What word is spelled c-a-t?"
    And card backs should be a concise one-sentence definition or example

  Scenario: Preview generated cards before saving
    Given I have entered the topic "CVC words for a beginning reader"
    When I tap "Generate Cards"
    Then I should see a preview list of generated cards
    And I should be able to remove individual cards before saving
    And I should be able to tap "Save (N)" to keep them

  Scenario: Regenerate cards if not satisfied
    Given I have previewed generated cards for "CVC words"
    When I tap "Regenerate"
    Then a new set of cards should be generated for the same topic

  Scenario: Adjust card count via slider up to 200
    Given I am on the AI generation screen
    When I move the "Cards to generate" slider to 50
    Then the card count badge should show 50

  Scenario: Enter a custom card count by tapping the count badge
    Given I am on the AI generation screen
    When I tap the card count badge
    And I type "75" in the dialog
    And I tap "OK"
    Then the card count should be set to 75

  Scenario: Custom card count is clamped between 1 and 200
    Given I am on the AI generation screen
    When I tap the count badge and enter 250
    Then the dialog should not accept the value and the count should remain unchanged



  Scenario: Load more cards without duplicates
    Given I have previewed 15 generated cards for "Animals"
    When I tap "Load More Cards"
    Then the AI should be called again with the existing card fronts as an exclusion list
    And any returned cards whose front matches an already-previewed card should be filtered out
    And a snackbar should report how many new cards were added
    And if no new unique cards are found a message "No new cards found — try rephrasing your topic." should appear

  Scenario: Load More is not shown for file-based generation
    Given I have uploaded a document and generated cards from it
    Then the "Load More Cards" button should not be visible

  Scenario: Add generated cards to an existing deck with duplicate skipping
    Given I have an existing deck named "Animals"
    When I select "Animals" in the "Save to" dropdown
    And I tap "Generate Cards"
    And I tap "Save"
    Then any cards whose front matches an existing card should be skipped
    And only new unique cards should be added to "Animals"
    And a snackbar should report how many were added and how many were skipped

  Scenario: Saved cards and deck share the same ID
    Given I tap "Generate Cards" with topic "Animals"
    When I tap "Save"
    Then the deck's ID and each flashcard's deckId should match
    And all generated cards should appear when the deck is opened

  Scenario: Generate a deck from an uploaded text file
    Given I tap "Generate with AI"
    When I tap "Upload Document"
    And I select a plain text or markdown file
    Then the document content should be parsed
    And flashcard suggestions should be extracted from the content

  Scenario: Capitalise first letter toggle defaults to on
    Given I am on the AI generation screen
    Then the "Capitalise first letter" toggle should be on by default
    When I tap "Generate Cards" with topic "animals"
    Then each card front and back should start with a capital letter

  Scenario: Turning off capitalisation preserves AI casing
    Given I am on the AI generation screen
    When I turn off the "Capitalise first letter" toggle
    And I tap "Generate Cards" with topic "animals"
    Then card fronts and backs should be returned exactly as the AI produced them


    Given I am on the AI generation screen
    When I tap "Generate Cards" with no topic entered and no file selected
    Then I should see a validation message

  Scenario: Generation failure shows an error
    Given the AI service is unavailable
    When I tap "Generate Cards" with topic "Animals"
    Then I should see an error message
    And no deck should be created
