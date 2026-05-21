Feature: Deck Import/Export (FEAT-006)
  As a user I want to export and import decks so I can share flashcards
  and restore them across devices.

  Scenario: Export a deck as JSON
    Given I have a deck with cards
    When I open the deck and tap the export button
    And I select "Export as JSON"
    Then the platform share sheet is triggered with a .json file

  Scenario: Export a deck as CSV
    Given I have a deck with cards
    When I open the deck and tap the export button
    And I select "Export as CSV"
    Then the platform share sheet is triggered with a .csv file

  Scenario: Import a JSON deck with no name conflict
    Given I have no decks
    When I tap the import button and pick a valid JSON file
    Then the deck appears in my deck list
    And a success snackbar is shown

  Scenario: Import a CSV deck with no name conflict
    Given I have no decks
    When I tap the import button and pick a valid CSV file
    Then the deck appears in my deck list
    And a success snackbar is shown

  Scenario: Import a deck with a duplicate name and choose Replace
    Given a deck named "Spanish Vocabulary" exists
    When I tap the import button and pick a JSON file for "Spanish Vocabulary"
    Then a duplicate deck dialog appears
    When I tap "Replace"
    Then the deck list contains "Spanish Vocabulary" with the imported cards
    And the original cards are removed

  Scenario: Import a deck with a duplicate name and choose Merge
    Given a deck named "Spanish Vocabulary" exists with some cards
    When I tap the import button and pick a JSON file for "Spanish Vocabulary" with new and overlapping cards
    Then a duplicate deck dialog appears
    When I tap "Merge"
    Then only the new cards are added to "Spanish Vocabulary"
    And existing cards are unchanged

  Scenario: User cancels the file picker
    Given I am on the deck list screen
    When I tap the import button and cancel the file picker
    Then the deck list is unchanged
    And no dialog or snackbar appears

  Scenario: User cancels at the duplicate dialog
    Given a deck named "French Words" exists
    When I tap the import button and pick a JSON file for "French Words"
    And I tap "Cancel" on the duplicate dialog
    Then "French Words" still exists with its original cards
