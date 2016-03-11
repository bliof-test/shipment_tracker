Feature: Alerting Unauthorised Releases
  As a user
  I should see slack notifications when deployment rules are violated
  So that appropriate actions can be taken

@mock_slack_notifier
Scenario: Alert dispatched for unauthorised deploy: Release has no approved Feature Reviews
  Given an application called "frontend"

  # An authorised deploy
  And a commit "#master1" with message "initial commit" is created at "2016-01-18 09:10:57"
  And a ticket "JIRA-ONE" with summary "Ticket ONE" is started at "2016-01-18 09:13:00"
  And developer prepares review known as "FR_ONE" for UAT "uat.fundingcircle.com" with apps
    | app_name | version  |
    | frontend | #master1 |
  And at time "2016-01-20 14:52:45" adds link for review "FR_ONE" to comment for ticket "JIRA-ONE"
  And ticket "JIRA-ONE" is approved by "bob@fundingcircle.com" at "2016-01-21 15:20:34"
  When commit "#master1" of "frontend" is deployed by "Jeff" to production at "2016-01-21 16:34:20"
  Then a deploy alert should not be dispatched

  # An unauthorised deploy
  And the branch "feature1" is checked out
  And a ticket "JIRA-TWO" with summary "Ticket TWO" is started at "2016-01-21 09:13:00"
  And a commit "#feat1_a" with message "feat1 first commit" is created at "2016-01-21 17:12:37"
  And developer prepares review known as "FR_TWO" for UAT "uat.fundingcircle.com" with apps
    | app_name | version  |
    | frontend | #feat1_a |
  And at time "2016-01-21 18:52:45" adds link for review "FR_TWO" to comment for ticket "JIRA-TWO"
  And the branch "master" is checked out
  And the branch "feature1" is merged with merge commit "#merge1" at "2016-01-22 16:14:39"
  When commit "#merge1" of "frontend" is deployed by "Jeff" to production at "2016-01-22 17:34:20"
  Then a deploy alert should be dispatched
