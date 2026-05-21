Feature: Study Analytics & Streaks
  As a learner
  I want to see my study streak, daily card counts, and accuracy
  So that I stay motivated and can track my progress

  Scenario: Streak badge appears after a study session
    Given I have completed a study session today
    When I return to the deck list
    Then I see a streak badge showing "1 day streak"

  Scenario: Streak continues for consecutive days
    Given I have completed study sessions on consecutive days
    When I return to the deck list
    Then the streak badge shows the correct day count

  Scenario: Streak resets after missing a day
    Given my last study session was two days ago
    When I view the deck list
    Then no streak badge is shown

  Scenario: Analytics screen shows 7-day bar chart
    Given I have studied on some days in the last week
    When I tap the analytics icon in the app bar
    Then the analytics screen opens and shows a bar chart with 7 bars

  Scenario: Accuracy is calculated correctly
    Given I rated 8 out of 10 cards as Good or Easy
    When I view the analytics screen
    Then the accuracy shows 80%

  Scenario: Analytics are accessible from the deck list
    Given I am on the deck list screen
    When I tap the bar chart icon in the app bar
    Then I navigate to the Study Analytics screen
