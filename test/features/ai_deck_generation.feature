Feature: AI Deck Generation
  As a user
  I want to generate flashcard decks from a topic or uploaded document
  So that I can quickly create study material without typing each card manually

  Scenario: Generate a deck from a topic prompt
    Given I am on the deck list screen
    When I tap "Generate with AI"
    And I enter the topic "CVC words for a beginning reader"
    And I tap "Generate"
    Then a new deck named "CVC Words" should be created
    And the deck should contain flashcards with CVC words on the front and pronunciation or meaning on the back

  Scenario: Preview generated cards before saving
    Given I have entered the topic "CVC words for a beginning reader"
    When I tap "Generate"
    Then I should see a preview list of generated cards
    And I should be able to remove individual cards before saving
    And I should be able to tap "Save Deck" to keep them

  Scenario: Regenerate cards if not satisfied
    Given I have previewed generated cards for "CVC words"
    When I tap "Regenerate"
    Then a new set of cards should be generated for the same topic

  Scenario: Generate a deck from an uploaded text file
    Given I tap "Generate with AI"
    When I tap "Upload Document"
    And I select a plain text or PDF file
    Then the document content should be parsed
    And flashcard suggestions should be extracted from the content

  Scenario: Cannot generate without a topic or file
    Given I am on the AI generation screen
    When I tap "Generate" with no topic entered and no file selected
    Then I should see a validation message

  Scenario: Generation failure shows an error
    Given the AI service is unavailable
    When I tap "Generate" with topic "Animals"
    Then I should see an error message
    And no deck should be created
