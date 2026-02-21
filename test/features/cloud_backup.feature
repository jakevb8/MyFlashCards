Feature: Cloud Backup
  As a signed-in user
  I want to back up and restore my flashcard data via Firebase
  So that I can access my decks across devices

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

  Scenario: Back up decks and flashcards
    Given I am signed in
    And I have 2 decks with a total of 5 flashcards
    When I tap "Back Up Now"
    Then all 2 decks should be uploaded to Firestore
    And all 5 flashcards should be uploaded to Firestore
    And I should see "Backed up 2 decks and 5 cards"

  Scenario: Restore decks and flashcards reloads app state
    Given I am signed in
    And Firestore contains 3 decks and 8 flashcards for my account
    When I tap "Restore"
    Then 3 decks and 8 flashcards should be written to local storage
    And the deck list should update immediately without restarting the app
    And I should see "Restored 3 decks and 8 cards"

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
