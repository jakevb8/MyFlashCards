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

  Scenario: Backup error shows a message
    Given I am signed in
    And Firestore is unavailable
    When I tap "Back Up Now"
    Then I should see an error message
