Feature: Settings
  As a user
  I want to manage my account and review the privacy policy
  So that I can control my data and understand how it is used

  Scenario: Settings screen is accessible from the deck list
    Given I am on the deck list screen
    When I tap the settings icon in the app bar
    Then I should be on the Settings screen

  Scenario: Signed-in user sees their account details in Settings
    Given I am signed in as "octocat"
    When I navigate to the Settings screen
    Then I should see "octocat" in the Account section
    And I should see a "Sign out" option
    And I should see a "Delete my account" option

  Scenario: Guest user does not see the Account section
    Given I am not signed in
    When I navigate to the Settings screen
    Then I should not see the Account section

  Scenario: Sign out from Settings
    Given I am signed in
    When I navigate to the Settings screen
    And I tap "Sign out"
    Then I should no longer be signed in
    And the Account section should no longer be visible

  Scenario: Delete account shows confirmation dialog
    Given I am signed in
    When I navigate to the Settings screen
    And I tap "Delete my account"
    Then a confirmation dialog should appear
    And I should see a destructive "Delete" button and a "Cancel" button

  Scenario: Cancel account deletion leaves data intact
    Given I am signed in
    When I navigate to the Settings screen
    And I tap "Delete my account"
    And I tap "Cancel" in the confirmation dialog
    Then my account should still exist
    And my local data should be unchanged

  Scenario: Confirmed account deletion removes all data
    Given I am signed in with local data present
    When I navigate to the Settings screen
    And I tap "Delete my account"
    And I confirm deletion
    Then all Firestore data under my user ID should be deleted
    And my Firebase Auth account should be deleted
    And my local Hive data should be cleared
    And the Account section should no longer be visible

  Scenario: Privacy policy is accessible from Settings
    Given I am on the Settings screen
    When I tap "Privacy Policy"
    Then I should see the Privacy Policy screen
    And it should describe what data is collected and how to delete it

  Scenario: App version is shown in About section
    Given I am on the Settings screen
    Then I should see a version number in the About section

Feature: Daily Review Reminders

  Scenario: Enable daily reminder
    Given I am on the Settings screen
    When I toggle the daily reminder on
    Then the reminder should be scheduled at the default time

  Scenario: Change reminder time
    Given I am on the Settings screen with reminders enabled
    When I change the reminder time to 8:00 AM
    Then the reminder should be rescheduled at 8:00 AM

  Scenario: Disable daily reminder
    Given I am on the Settings screen with reminders enabled
    When I toggle the daily reminder off
    Then the reminder should be cancelled

Feature: Study Goals & Milestones

  Scenario: Daily goal is shown in Settings
    Given I am on the Settings screen
    Then I should see the daily goal in the Study Goals section

  Scenario: User can change daily goal
    Given I am on the Settings screen
    When I tap the daily goal and enter 20
    Then the daily goal should be updated to 20

  Scenario: Daily goal progress banner appears on deck list
    Given I have reviewed 5 cards today
    And my daily goal is 10
    When I am on the deck list screen
    Then I should see a progress indicator showing 5 of 10 cards reviewed

  Scenario: Confetti fires when first session milestone is hit
    Given I have never completed a study session before
    When I complete a study session
    Then confetti should be shown on the completion screen
    And the milestone should be marked as seen

  Scenario: Confetti does not fire for already-seen milestones
    Given I have already seen the first-session milestone
    When I complete a study session
    Then no confetti should be shown
