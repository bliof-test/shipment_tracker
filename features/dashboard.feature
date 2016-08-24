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
    | Jira Key | Summary       | Description                       | Deploys                      |
    | ENG-3    | Another story | As a User implement another story | GB 2016-03-21 12:02 UTC Jeff |
    | ENG-2    | Another task  | As a User implement another task  | GB 2016-03-21 12:02 UTC Jeff |

@mock_slack_notifier
Scenario: User finds tickets by deployed app name
  Given the following tickets are created:
    | Jira Key | Summary     | Description | Deploys                     |
    | ENG-1    | First task  | Something   |                             |
    | ENG-2    | Second task | Something   | 2016-03-21 12:02 app_1 #abc |
    | ENG-3    | Third task  | Something   | 2016-03-22 15:13 app_2 #def |
  When I search tickets with keywords "app_1"
  Then I should find the following tickets on the dashboard:
    | Jira Key | Summary     | Description | Deploys                      |
    | ENG-2    | Second task | Something   | GB 2016-03-21 12:02 UTC Jeff |

@mock_slack_notifier
Scenario: User finds ticket by title
  Given the following tickets are created:
    | Jira Key | Summary                 | Description                    | Deploys                     |
    | ENG-1    | Make this task          | As a User\n make the task      | 2016-03-21 12:02 app_1 #abc |
    | ENG-2    | Implement this critical | As a User\n do another task    | 2016-03-22 15:13 app_2 #def |
    | ENG-3    | Perform that issue      | As a User\n perform some story | 2016-03-22 16:13 app_3 #ghj |
  When I search tickets with keywords "implement issue"
  Then I should find the following tickets on the dashboard:
    | Jira Key | Summary                 | Description                  | Deploys                      |
    | ENG-2    | Implement this critical | As a User do another task    | GB 2016-03-22 15:13 UTC Jeff |
    | ENG-3    | Perform that issue      | As a User perform some story | GB 2016-03-22 16:13 UTC Jeff |

@mock_slack_notifier
Scenario: User finds ticket by commit version
  Given the following tickets are created:
    | Jira Key | Summary                 | Description                    | Deploys                     |
    | ENG-1    | Make this task          | As a User\n make the task      | 2016-03-21 12:02 app_1 #abc |
    | ENG-2    | Implement this critical | As a User\n do another task    | 2016-03-22 15:13 app_2 #def |
    | ENG-3    | Perform that issue      | As a User\n perform some story | 2016-03-22 16:13 app_3 #ghj |
  When I search tickets with keywords "#def"
  Then I should find the following tickets on the dashboard:
    | Jira Key | Summary                 | Description                  | Deploys                      |
    | ENG-2    | Implement this critical | As a User do another task    | GB 2016-03-22 15:13 UTC Jeff |

Scenario: User finds ticket by commit version deployed inherently
  Given an application called "frontend"
  # First feature developed and merged but not deployed
  And a commit "#master1" with message "first commit" is created at "2016-01-18 09:10:57"
  And a ticket "JIRA-ONE" with summary "Ticket ONE" is started at "2016-01-18 09:13:00"
  And developer prepares review known as "FR_ONE" for UAT "uat.fundingcircle.com" with apps
    | app_name | version  |
    | frontend | #master1 |
  And at time "2016-01-20 14:52:45" adds link for review "FR_ONE" to comment for ticket "JIRA-ONE"
  And ticket "JIRA-ONE" is approved by "bob@fundingcircle.com" at "2016-01-21 15:20:34"
  # Second feature developed, merged and deployed to production
  And a commit "#master2" with message "second commit" is created at "2016-02-18 09:10:57"
  And a ticket "JIRA-TWO" with summary "Ticket TWO" is started at "2016-02-18 09:13:00"
  And developer prepares review known as "FR_TWO" for UAT "uat.fundingcircle.com" with apps
    | app_name | version  |
    | frontend | #master2 |
  And at time "2016-02-20 14:52:45" adds link for review "FR_TWO" to comment for ticket "JIRA-TWO"
  And ticket "JIRA-TWO" is approved by "bob@fundingcircle.com" at "2016-02-21 15:20:34"
  And commit "#master2" of "frontend" is deployed by "Jeff" to production at "2016-02-21 16:34:20"
  When I search tickets with keywords "#master1"
  Then I should find the following tickets on the dashboard:
    | Jira Key | Summary    | Description | Deploys |
    | JIRA-ONE | Ticket ONE |             |         |

@mock_slack_notifier
Scenario: User finds ticket by title filtered by date
  Given the following tickets are created:
    | Jira Key | Summary            | Description                    | Deploys                     |
    | ENG-1    | Make this task     | As a User\n make the task      | 2016-03-21 12:02 app_1 #abc |
    | ENG-2    | Implement this     | As a User\n do another task    | 2016-03-22 15:13 app_2 #def |
    | ENG-3    | Perform that issue | As a User\n perform some story | 2016-03-23 16:13 app_3 #ghj |
    | ENG-4    | Perform that task  | As a User\n do another story   | 2016-03-24 16:13 app_3 #ikl |
  When I search tickets with keywords:
    | Query                | From       | To         |
    | make implement story | 2016-03-22 | 2016-03-23 |
  Then I should find the following tickets on the dashboard:
    | Jira Key | Summary            | Description                  | Deploys                      |
    | ENG-2    | Implement this     | As a User do another task    | GB 2016-03-22 15:13 UTC Jeff |
    | ENG-3    | Perform that issue | As a User perform some story | GB 2016-03-23 16:13 UTC Jeff |
