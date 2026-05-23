Feature: Deck Sharing via Link
  As a user
  I want to share a deck via a deep link
  So that other users can import a copy of my deck

  Scenario: User shares a deck from the deck list
    Given I have a deck with cards
    When I swipe the deck tile and tap "Share"
    Then I see a bottom sheet with a shareable link
    And the link starts with "myflashcards://deck/"

  Scenario: User shares a deck from the flashcard list
    Given I am viewing a deck's flashcard list
    When I tap the share icon and select "Share via Link"
    Then I see a bottom sheet with a shareable link

  Scenario: User copies the share link
    Given I see the share bottom sheet with a generated link
    When I tap the copy icon
    Then the link is copied to the clipboard

  Scenario: User opens a valid share link
    Given another user has shared a deck link
    When I open the app via the deep link "myflashcards://deck/{shareId}"
    Then I am prompted to import the shared deck
    And the imported deck has fresh spaced-repetition progress

  Scenario: User opens an expired share link
    Given a deck share link that has expired
    When I open the app via the expired deep link
    Then I see an error message "This share link has expired."

  Scenario: User imports a shared deck with a name conflict
    Given I have a deck named "Biology"
    And another user shared a deck also named "Biology"
    When I open the app via the share link
    Then I am prompted to replace or merge with the existing deck
