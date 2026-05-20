Feature: Cloud Backup
  As a signed-in user
  I want to back up and restore my flashcard data via Firebase
  So that I can access my decks across devices and restore to a previous state

  Scenario: GitHub sign-in opens OAuth flow
    Given I am not signed in
    When I tap "Sign in with GitHub"
    Then the GitHub OAuth browser flow is initiated

  Scenario: Signed-in user is displayed
    Given I have signed in with GitHub as "octocat"
    When I navigate to the Cloud Backup screen
    Then I should see my display name "octocat"
    And I should see a "Back Up Now" button
    And I should see a "Restore" button

  Scenario: Back up decks, flashcards, and theme settings
    Given I am signed in
    And I have 2 decks with a total of 5 flashcards
    And the current theme is "Ocean Blue" in dark mode with kids mode off
    When I tap "Back Up Now"
    Then all 2 decks should be uploaded to Firestore
    And all 5 flashcards should be uploaded to Firestore (including starCount and archived)
    And the theme settings should be saved to Firestore
    And I should see "Backed up 2 decks and 5 cards"

  Scenario: Restore clears local data before writing cloud data
    Given I am signed in
    And I have 1 local deck that is NOT in Firestore
    And Firestore contains 3 decks and 8 flashcards for my account
    When I tap "Restore"
    Then all local decks and cards should be cleared first
    And 3 decks and 8 flashcards should be written to local storage
    And the deck list should update immediately without restarting the app
    And I should see "Restored 3 decks and 8 cards"

  Scenario: Restore also restores theme settings
    Given I am signed in
    And Firestore has theme settings: "Sunshine", light mode, kids mode on
    When I tap "Restore"
    Then the active theme should be "Sunshine"
    And kids mode should be on

  Scenario: Restore with star and archive data intact
    Given I am signed in
    And Firestore contains a card with starCount 2 and archived false
    When I tap "Restore"
    Then the local card should have starCount 2 and archived false

  Scenario: Cannot back up when not signed in
    Given I am not signed in
    When I navigate to the Cloud Backup screen
    Then I should see "Sign in with GitHub"
    And I should not see "Back Up Now"

  Scenario: Sign out
    Given I am signed in
    When I tap "Sign out"
    Then I should no longer be signed in
    And I should see "Sign in with GitHub"

  Scenario: Back up removes deleted decks and cards from Firestore
    Given I am signed in
    And Firestore contains a deck that I have since deleted locally
    When I tap "Back Up Now"
    Then the deleted deck should be removed from Firestore
    And only currently local decks and cards should remain in Firestore

  Scenario: Backup screen shows last backed up time after a successful backup
    Given I am signed in
    And I have previously backed up my data
    When I navigate to the Cloud Backup screen
    Then I should see "Last backed up" with a relative time

  Scenario: Backup screen shows "Never backed up" when no backup exists
    Given I am signed in
    And I have never backed up
    When I navigate to the Cloud Backup screen
    Then I should see "Never backed up"

  Scenario: Incremental backup skips unchanged records
    Given I am signed in
    And I have 3 decks already in Firestore with the same updatedAt as local
    When I tap "Back Up Now"
    Then zero deck documents should be written to Firestore
    And the meta document should still be updated

  Scenario: Restore shows confirmation dialog with counts before wiping data
    Given I am signed in
    And Firestore contains a backup of 4 decks and 12 cards
    When I tap "Restore"
    Then a confirmation dialog should appear showing "4 decks and 12 cards"
    And local data should not be cleared until the user confirms

  Scenario: Restore is cancelled from confirmation dialog
    Given I am signed in
    And Firestore contains a backup
    When I tap "Restore"
    And I tap "Cancel" in the confirmation dialog
    Then local data should remain unchanged

  Scenario: Schema version mismatch shows an error on restore
    Given I am signed in
    And Firestore contains documents with schemaVersion 99
    When I tap "Restore"
    Then I should see an error message mentioning the schema version

