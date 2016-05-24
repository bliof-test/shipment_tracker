@mock_slack_notifier
Feature: Alerting deploys of unauthorised Releases
  As a user
  I should see slack notifications when deployment rules are violated
  So that appropriate actions can be taken

Scenario: Release has no approved Feature Reviews
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
  When commit "#merge1" of "frontend" is deployed by "Joe" to production at "2016-01-22 17:34:20"
  Then a deploy alert should be dispatched for
    | app_name | version | time                   | deployer | message                                              |
    | frontend | #merge1 | 2016-01-22 17:34+00:00 | Joe      | Release not authorised; Feature Review not approved. |

Scenario: Dependent release has no approved Feature Reviews
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

  # An unauthorised release
  And the branch "feature1" is checked out
  And a ticket "JIRA-TWO" with summary "Ticket TWO" is started at "2016-01-21 09:13:00"
  And a commit "#feat1_a" with message "feat1 first commit" is created at "2016-01-21 17:12:37"
  And developer prepares review known as "FR_TWO" for UAT "uat.fundingcircle.com" with apps
    | app_name | version  |
    | frontend | #feat1_a |
  And at time "2016-01-21 18:52:45" adds link for review "FR_TWO" to comment for ticket "JIRA-TWO"
  And the branch "master" is checked out
  And the branch "feature1" is merged with merge commit "#merge1" at "2016-01-22 16:14:39"

  # An authorised release, and deployed
  And the branch "feature2" is checked out
  And a ticket "JIRA-THREE" with summary "Ticket THREE" is started at "2016-01-23 09:13:00"
  And a commit "#feat2_a" with message "feat2 first commit" is created at "2016-01-23 17:12:37"
  And developer prepares review known as "FR_THREE" for UAT "uat.fundingcircle.com" with apps
    | app_name | version  |
    | frontend | #feat2_a |
  And at time "2016-01-23 18:52:45" adds link for review "FR_THREE" to comment for ticket "JIRA-THREE"
  And the branch "master" is checked out
  And the branch "feature2" is merged with merge commit "#merge2" at "2016-01-24 16:14:39"
  And ticket "JIRA-THREE" is approved by "bob@fundingcircle.com" at "2016-01-24 16:20:34"

  When commit "#merge2" of "frontend" is deployed by "Joe" to production at "2016-01-24 17:34:20"
  Then a deploy alert should be dispatched for
    | app_name | version | time                   | deployer | message                                              |
    | frontend | #merge2 | 2016-01-24 17:34+00:00 | Joe      | Release not authorised; Feature Review not approved. |

Scenario: Rollback to an older software version
  Given an application called "frontend"

  # An authorised deploy
  And a commit "#master1" with message "first commit" is created at "2016-01-18 09:10:57"
  And a ticket "JIRA-ONE" with summary "Ticket ONE" is started at "2016-01-18 09:13:00"
  And developer prepares review known as "FR_ONE" for UAT "uat.fundingcircle.com" with apps
    | app_name | version  |
    | frontend | #master1 |
  And at time "2016-01-20 14:52:45" adds link for review "FR_ONE" to comment for ticket "JIRA-ONE"
  And ticket "JIRA-ONE" is approved by "bob@fundingcircle.com" at "2016-01-21 15:20:34"
  When commit "#master1" of "frontend" is deployed by "Jeff" to production at "2016-01-21 16:34:20"
  Then a deploy alert should not be dispatched

  # An authorised deploy
  And a commit "#master2" with message "second commit" is created at "2016-02-18 09:10:57"
  And a ticket "JIRA-TWO" with summary "Ticket TWO" is started at "2016-02-18 09:13:00"
  And developer prepares review known as "FR_TWO" for UAT "uat.fundingcircle.com" with apps
    | app_name | version  |
    | frontend | #master2 |
  And at time "2016-02-20 14:52:45" adds link for review "FR_TWO" to comment for ticket "JIRA-TWO"
  And ticket "JIRA-TWO" is approved by "bob@fundingcircle.com" at "2016-02-21 15:20:34"
  When commit "#master2" of "frontend" is deployed by "Jeff" to production at "2016-02-21 16:34:20"
  Then a deploy alert should not be dispatched

  # An unauthorised rollback deploy
  When commit "#master1" of "frontend" is deployed by "Joe" to production at "2016-03-21 16:34:20"
  Then a deploy alert should be dispatched for
    | app_name | version  | time                   | deployer | message                                             |
    | frontend | #master1 | 2016-03-21 16:34+00:00 | Joe      | Old release deployed. Was the rollback intentional? |
