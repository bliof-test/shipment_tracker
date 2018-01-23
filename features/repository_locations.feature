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
    | Name      | URI                            | Repo Owners | Repo Approvers |
    | new_app   | ssh://github.com/new_app       |             |                |
    | new_app_2 | ssh://github.com/new_app_2.git |             |                |

@disable_repo_verification
Scenario: Add repository with auto-generated tokens
  Given I am on the new repository location form
  When I enter a valid uri "ssh://git@github.com/owner/app_name.git"
  And I visit the tokens page
  Then I should see the tokens
    | Source               | Name     | Endpoint        |
    | CircleCI (webhook)   | app_name | circleci        |
    | Deployment           | app_name | deploy          |

@disable_repo_verification
Scenario: Add owners of a repository
  Given "new-app" repository
  And I am on the edit repository location form for "new-app"
  When I enter owner emails "repo-owner@example.com, second-repo-owner@example.com"
  And I click "Update Git Repository"
  Then I should see the repository locations:
    | Name      | URI                | Repo Owners                                           | Repo Approvers |
    | new-app   | uri_for("new-app") | repo-owner@example.com, second-repo-owner@example.com |                |

@disable_repo_verification
  Scenario: Add approvers of a repository
    Given "new-app" repository
    And I am on the edit repository location form for "new-app"
    When I enter approver emails "repo-approver@example.com, second-repo-approver@example.com"
    And I click "Update Git Repository"
    Then I should see the repository locations:
    | Name      | URI                | Repo Owners | Repo Approvers                                              |
    | new-app   | uri_for("new-app") |             | repo-approver@example.com, second-repo-approver@example.com |

@disable_repo_verification
Scenario: Edit owners of a repository
  Given "new-app" repository
  And owner of "new-app" is "test@example.com"
  And I am on the edit repository location form for "new-app"
  When I enter owner emails "repo-owner@example.com, second-repo-owner@example.com"
  And I click "Update Git Repository"
  Then I should see the repository locations:
    | Name      | URI                | Repo Owners                                           | Repo Approvers |
    | new-app   | uri_for("new-app") | repo-owner@example.com, second-repo-owner@example.com |                |

@disable_repo_verification
Scenario: Edit approvers of a repository
  Given "new-app" repository
  And approver of "new-app" is "test@example.com"
  And I am on the edit repository location form for "new-app"
  When I enter approver emails "repo-approver@example.com, second-repo-approver@example.com"
  And I click "Update Git Repository"
  Then I should see the repository locations:
    | Name      | URI                | Repo Owners | Repo Approvers                                              |
    | new-app   | uri_for("new-app") |             | repo-approver@example.com, second-repo-approver@example.com |

@disable_repo_verification
Scenario: Select ISAE 3402 audit option for a repository
  Given "new-app" repository
  And I am on the edit repository location form for "new-app"
  When I select audit options "isae_3402"
  When I click "Update Git Repository"
  And I am on the edit repository location form for "new-app"
  Then the previously set "isae_3402" audit options should be selected
