@logged_in
Feature: Managing Repository Locations
  As an application onboarder
  I want to add a repository from GitHub
  Because I want an audit trail of the application's development

Scenario: Add repository locations
  Given I am on the new repository location form
  When I enter a valid uri "ssh://example.com/new_app"
  When I enter a valid uri "ssh://example.com/new_app_2.git"
  Then I should see the repository locations:
    | Name      | URI                             |
    | new_app   | ssh://example.com/new_app       |
    | new_app_2 | ssh://example.com/new_app_2.git |
