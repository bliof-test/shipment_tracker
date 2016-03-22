@logged_in
Feature: Searching for releases on Dashboard
  As a user
  I want to full text search for tickets
  So I can find tickets related to any topic

Scenario: User finds deployed tickets by description
  Given the following tickets are created:
    | Jira Key | Summary       | Description                         | Deploys                     |
    | ENG-1    | This task     | As a User\n implement the task      | 2016-03-21 12:02 app_1 #abc |
    | ENG-2    | Another task  | As a User\n implement another task  | 2016-03-21 12:02 app_1 #def |
    | ENG-3    | Another story | As a User\n implement another story | 2016-03-21 12:02 app_1 #ghi |
    | ENG-4    | Another story | As a User\n implement another story |                             |
  When I search tickets with keywords "another story"
  Then I should find the following tickets on the dashboard:
    | Jira Key | Summary       | Description                       | Deploys                         |
    | ENG-3    | Another story | As a User implement another story | GB 2016-03-21 12:02 UTC app_1 #ghi |
    | ENG-2    | Another task  | As a User implement another task  | GB 2016-03-21 12:02 UTC app_1 #def |

@mock_slack_notifier
Scenario: User finds tickets by deployed app name
  Given the following tickets are created:
    | Jira Key | Summary     | Description | Deploys                     |
    | ENG-1    | First task  | Something   |                             |
    | ENG-2    | Second task | Something   | 2016-03-21 12:02 app_1 #abc |
    | ENG-3    | Third task  | Something   | 2016-03-22 15:13 app_2 #def |
  When I search tickets with keywords "app_1"
  Then I should find the following tickets on the dashboard:
    | Jira Key | Summary     | Description | Deploys                         |
    | ENG-2    | Second task | Something   | GB 2016-03-21 12:02 UTC app_1 #abc |
