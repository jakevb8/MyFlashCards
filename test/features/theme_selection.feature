Feature: Theme Selection
  As a user
  I want to choose a visual theme for the app and switch between adult and kids palettes
  So that I can personalise the look and feel for myself or a child

  Scenario: Default theme is Classic (adult)
    Given the app has just launched
    Then the active theme should be "Classic"
    And the brightness should be "system"
    And kids mode should be off

  Scenario: Theme choice persists across app restarts
    Given I have selected the "Ocean Blue" theme with "Dark" brightness
    When I close and relaunch the app
    Then the active theme should be "Ocean Blue"
    And the brightness should be "dark"

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

  Scenario: Toggle to kids mode shows kids themes
    Given the app is on the "Classic" theme with kids mode off
    When I open the theme picker
    And I toggle kids mode on
    Then kids mode should be on
    And the active theme should be "Sunshine"
    And the theme picker should show kids themes: Sunshine, Jungle, Bubblegum, Super Hero

  Scenario: Toggle back to adult mode restores adult themes
    Given kids mode is on with theme "Sunshine"
    When I open the theme picker
    And I toggle kids mode off
    Then kids mode should be off
    And the active theme should be "Classic"

  Scenario: Selecting a kids theme while in kids mode applies immediately
    Given kids mode is on
    When I open the theme picker
    And I select the "Bubblegum" theme
    Then the active theme should be "Bubblegum"

  Scenario: Kids mode persists across app restarts
    Given kids mode is on with theme "Jungle"
    When I close and relaunch the app
    Then kids mode should be on
    And the active theme should be "Jungle"

    Then the brightness should be "system"

  Scenario: Theme and brightness change independently
    Given the app is on the "Classic" theme with "system" brightness
    When I select the "Rose Garden" theme
    And I select "Dark" brightness
    Then the active theme should be "Rose Garden"
    And the brightness should be "dark"
