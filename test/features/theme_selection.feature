Feature: Theme Selection
  As a user
  I want to choose a visual theme for the app
  So that I can personalise the look and feel

  Scenario: Default theme is Classic
    Given the app has just launched
    Then the active theme should be "Classic"
    And the brightness should be "system"

  Scenario: Switch to Ocean Blue theme
    Given the app is on the "Classic" theme
    When I open the theme picker
    And I select the "Ocean Blue" theme
    Then the active theme should be "Ocean Blue"

  Scenario: Switch to Rose Garden theme
    Given the app is on the "Classic" theme
    When I open the theme picker
    And I select the "Rose Garden" theme
    Then the active theme should be "Rose Garden"

  Scenario: Switch to Executive theme
    Given the app is on the "Classic" theme
    When I open the theme picker
    And I select the "Executive" theme
    Then the active theme should be "Executive"

  Scenario: Set brightness to Dark
    Given the brightness is "system"
    When I open the theme picker
    And I select "Dark" brightness
    Then the brightness should be "dark"

  Scenario: Set brightness to Light
    Given the brightness is "dark"
    When I open the theme picker
    And I select "Light" brightness
    Then the brightness should be "light"

  Scenario: Set brightness back to System
    Given the brightness is "light"
    When I open the theme picker
    And I select "System" brightness
    Then the brightness should be "system"

  Scenario: Theme and brightness change independently
    Given the app is on the "Classic" theme with "system" brightness
    When I select the "Rose Garden" theme
    And I select "Dark" brightness
    Then the active theme should be "Rose Garden"
    And the brightness should be "dark"
