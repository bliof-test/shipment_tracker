@logged_in
Feature: Managing Repository Locations
  As an application onboarder
  I want to add a repository from GitHub
  Because I want an audit trail of the application's development

@disable_repo_verification
Scenario: Add repositories
  Given I am on the new repository location form
  When I enter a valid uri "ssh://github.com/new_app"
  When I enter a valid uri "ssh://github.com/new_app_2.git"
  Then I should see the repository locations:
    | Name      | URI                            |
    | new_app   | ssh://github.com/new_app       |
    | new_app_2 | ssh://github.com/new_app_2.git |

@disable_repo_verification
Scenario: Add repository with auto-generated tokens
  Given I am on the new repository location form
  When I enter a valid uri "ssh://git@github.com/owner/app_name.git"
  And I select the tokens for auto-generation:
    | Tokens             |
    | circleci (webhook) |
    | circleci (curl)    |
    | deployment         |
  And I visit the tokens page
  Then I should see the tokens
  | Token type         | Token name |
  | circleci (webhook) | app_name   |
  | circleci (curl)    | app_name   |
  | deployment         | app_name   |
