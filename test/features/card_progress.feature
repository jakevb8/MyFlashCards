Feature: Card Progress Tracking
  As a user
  I want to mark cards I know with stars
  So that I can track my progress and archive mastered cards

  Scenario: Star a card for the first time
    Given a deck contains a card with 0 stars
    When I tap the star button on that card
    Then the card should show 1 star
    And the card should not be archived

  Scenario: Star a card a second time
    Given a deck contains a card with 1 star
    When I tap the star button on that card
    Then the card should show 2 stars
    And the card should not be archived

  Scenario: Starring a card for the third time archives it
    Given a deck contains a card with 2 stars
    When I tap the star button on that card
    Then the card should be archived
    And the card should no longer appear in the active card list
    And the card should appear in the archived section

  Scenario: Archived cards are excluded from study sessions
    Given a deck contains 3 active cards and 1 archived card
    When I start a study session for that deck
    Then the session should contain 3 cards
    And the archived card should not appear

  Scenario: Archived cards are sorted to the back during study (pre-archive)
    Given a deck contains cards with star counts 0, 1, and 2
    When I start a study session in order
    Then cards with more stars should appear later in the session

  Scenario: Unarchive a card resets its star count
    Given a deck contains an archived card
    When I tap "Unarchive" on that card in the archived section
    Then the card should be returned to the active list with 0 stars

  Scenario: Star button is visible during a study session
    Given I am studying a deck with at least one card
    Then I should see a star button below the navigation buttons
    And it should show the current star count for the visible card

  Scenario: Star a card during a study session
    Given I am studying a deck and viewing a card with 1 star
    When I tap the star button during the study session
    Then the card's star count should increment to 2
    And the star button should update immediately

  Scenario: Star count and archived status are backed up to Firestore
    Given I am signed in
    And I have a card with 2 stars
    When I tap "Back Up Now"
    Then the card in Firestore should have starCount 2 and archived false

  Scenario: Star count and archived status are restored from Firestore
    Given I am signed in
    And Firestore contains a card with starCount 3 and archived true
    When I tap "Restore"
    Then the local card should have starCount 3 and archived true
