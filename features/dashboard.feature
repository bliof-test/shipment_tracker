Feature: Searching for releases on Dashboard

  As a user,
  I want to free text search for tickets,
  so I can find tickets related to any topic.

Scenario: User finds ticket by description

Given the following tickets are created:
  | Jira Key | Summary | Description |
  | ENG-1 | Make this task | As a User\r\n implement the task |
  | ENG-2 | Make another task | As a User\r\n implement another task |
  | ENG-2 | Make another story | As a User\r\n implement another story |
When I search tickets with keywords "another story"
Then I should find the following ticket on the dashboard:
  | Jira Key | Summary | Description |
  | ENG-2 | Make another task | As a User implement another task |
  | ENG-2 | Make another story | As a User implement another story |
