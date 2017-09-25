Feature: Feature Review
  As a Developer
  I want to create a Feature Review
  In order for a Product Owner to review the feature I worked on

@logged_in
Scenario: Preparing a Feature Review
  Given an application called "frontend"
  And an application called "backend"

  # 2014-10-04
  And a commit "#abc" by "Alice" is created at "2014-10-04 11:00:00" for app "frontend"
  And a commit "#def" by "Bob" is created at "2014-10-04 12:30:00" for app "backend"

  # Today
  When I prepare a feature review for:
    | field name      | content             |
    | frontend        | #abc                |
    | backend         | #def                |
  Then I should see the feature review page with the applications:
    | app_name | version |
    | frontend | #abc    |
    | backend  | #def    |

@logged_in
Scenario: Editing a Feature Review not yet linked to a ticket
  Given an application called "frontend"
    And an application called "backend"

    And a commit "#abc" by "Alice" is created at "2014-10-04 11:00:00" for app "frontend"
    And a commit "#def" by "Bob" is created at "2014-10-04 12:30:00" for app "backend"
    And I prepare a feature review for:
      | field name      | content |
      | frontend        | #abc    |

  When I click modify button on review panel
    And I fill in the data for a feature review:
      | field name      | content             |
      | backend         | #def                |
  Then I should see the feature review page with the applications:
    | app_name | version |
    | frontend | #abc    |
    | backend  | #def    |

@logged_in @disable_jira_client
Scenario: Linking a Feature Review
  Given an application called "frontend"
    And a commit "#abc" by "Alice" is created at "2014-10-04 11:00:00" for app "frontend"
    And a ticket "JIRA-123" with summary "Urgent ticket" is started at "2014-10-04 13:01:17"
    And developer prepares review known as "FR_view" with apps
      | app_name | version |
      | frontend | #abc    |

  When I visit the feature review known as "FR_view"
  When I link the feature review "FR_view" to the Jira ticket "JIRA-123"
  Then I should see an alert: "Feature Review was linked to JIRA-123. Refresh this page in a moment and the ticket will appear."

  When I reload the page after a while
  Then I should see the tickets
    | Ticket   | Summary       | Status      |
    | JIRA-123 | Urgent ticket | In Progress |

  When I link the feature review "FR_view" to the Jira ticket "JIRA-123"
  Then I should see an alert: "Failed to link JIRA-123. Duplicate tickets should not be added."

@logged_in @disable_jira_client
Scenario: Unlinking a ticket from a Feature Review
  Given an application called "frontend"
  And a commit "#abc" by "Alice" is created at "2014-10-04 11:00:00" for app "frontend"
  And a ticket "JIRA-123" with summary "Urgent ticket" is started at "2014-10-04 13:01:17"
  And a ticket "JIRA-789" with summary "Urgent ticket" is started at "2014-10-04 13:01:17"
  And developer prepares review known as "FR_view" with apps
    | app_name | version |
    | frontend | #abc    |

  When I visit the feature review known as "FR_view"
  When I link the feature review "FR_view" to the Jira ticket "JIRA-123"
  And I link the feature review "FR_view" to the Jira ticket "JIRA-789"

  When I reload the page after a while
  Then I should see the tickets
    | Ticket   | Summary       | Status      |
    | JIRA-123 | Urgent ticket | In Progress |
    | JIRA-789 | Urgent ticket | In Progress |

  When I unlink the feature review "FR_view" from the Jira ticket "JIRA-123"

  When I reload the page after a while
  Then I should see the tickets
    | Ticket   | Summary       | Status      |
    | JIRA-789 | Urgent ticket | In Progress |

@logged_in
Scenario: Viewing a Feature Review
  Given an application called "frontend"
  And an application called "backend"
  And an application called "mobile"
  And an application called "irrelevant"

  # 2014-10-04
  And a ticket "JIRA-123" with summary "Urgent ticket" is started at "2014-10-04 13:01:17"

  # 2014-10-05
  And a commit "#abc" by "Alice" is created at "2014-10-05 11:01:00" for app "frontend"
  And a commit "#old" by "Bob" is created at "2014-10-05 11:02:00" for app "backend"
  And a commit "#def" by "Bob" is created at "2014-10-05 11:03:00" for app "backend"
  And a commit "#ghi" by "Carol" is created at "2014-10-05 11:04:00" for app "mobile"
  And a commit "#xyz" by "Wendy" is created at "2014-10-05 11:05:00" for app "irrelevant"
  And At "2014-10-05 12:00:00" CircleCi "passes" for commit "#abc"
  And At "2014-10-05 12:05:00" CircleCi "fails" for commit "#def"
  # Build retriggered and passes second time.
  And At "2014-10-05 12:23:00" CircleCi "passes" for commit "#def"
  And commit "#abc" of "frontend" is deployed by "Alice" to server "uat.fundingcircle.com" at "2014-10-05 13:00:00"
  And commit "#old" of "backend" is deployed by "Bob" to server "uat.fundingcircle.com" at "2014-10-05 13:11:00"
  And commit "#def" of "backend" is deployed by "Bob" to server "other-uat.fundingcircle.com" at "2014-10-05 13:48:00"
  And commit "#xyz" of "irrelevant" is deployed by "Wendy" to server "uat.fundingcircle.com" at "2014-10-05 14:05:00"
  And developer prepares review known as "FR_view" with apps
    | app_name | version |
    | frontend | #abc    |
    | backend  | #def    |
    | mobile   | #ghi    |
  And at time "2014-10-05 16:00:01" adds link for review "FR_view" to comment for ticket "JIRA-123"
  And ticket "JIRA-123" is approved by "jim@fundingcircle.com" at "2014-10-05 17:30:10"

  When I visit the feature review known as "FR_view"

  Then I should see that the Feature Review was approved at "2014-10-05 17:30:10"

  And I should see the tickets
    | Ticket   | Summary       | Status               |
    | JIRA-123 | Urgent ticket | Ready for Deployment |

  And I should see a summary with heading "warning" and content
    | status  | title                    |
    | warning | Unit Test Results        |
    | warning | Integration Test Results |
    | warning | QA Acceptance            |
    | warning | Repo Owner Commentary    |

  And I should see the builds with heading "warning" and content
    | Status  | App      | Source   |
    | success | frontend | CircleCi |
    | success | backend  | CircleCi |
    | warning | mobile   |          |

@logged_in
Scenario: Viewing a Feature Review that requires re-approval
  Given an application called "frontend"
  And a ticket "JIRA-1" with summary "Some work" is started at "2014-10-11 13:01:17"
  And a commit "#abc" by "Alice" is created at "2014-10-12 11:01:00" for app "frontend"
  And ticket "JIRA-1" is approved by "jim@fundingcircle.com" at "2014-10-13 17:30:10"
  And developer prepares review known as "FR" with apps
    | app_name | version |
    | frontend | #abc    |
  And at time "2014-10-14 16:00:01" adds link for review "FR" to comment for ticket "JIRA-1"

  When I visit the feature review known as "FR"

  Then I should see that the Feature Review requires reapproval
  And I should see the tickets
    | Ticket | Summary   | Status              |
    | JIRA-1 | Some work | Requires reapproval |

@logged_in
Scenario: Viewing a Feature Review as at a specified time
  Given an application called "frontend"

  And a ticket "JIRA-123" with summary "Urgent ticket" is started at "2014-10-04 13:00:00"
  And a commit "#abc" by "Alice" is created at "2014-10-04 13:05:00" for app "frontend"
  And developer prepares review known as "FR_123" with apps
    | app_name | version |
    | frontend | #abc    |
  And at time "2014-10-04 14:00:00.500" adds link for review "FR_123" to comment for ticket "JIRA-123"

  When I visit feature review "FR_123" as at "2014-10-04 14:00:00"

  Then I should see the tickets
    | Ticket   | Summary       | Status      |
    | JIRA-123 | Urgent ticket | In Progress |

  And I should see the time "2014-10-04 14:00:00" for the Feature Review

@logged_in
Scenario: Viewing an approved Feature Review after regenerating snapshots
  Given an application called "frontend"

  And a ticket "JIRA-123" with summary "Urgent ticket" is started at "2014-10-04 13:00:00"
  And a commit "#abc" by "Alice" is created at "2014-10-04 13:05:00" for app "frontend"
  And developer prepares review known as "FR_123" with apps
    | app_name | version |
    | frontend | #abc    |
  And at time "2014-10-04 14:00:00.500" adds link for review "FR_123" to comment for ticket "JIRA-123"
  And ticket "JIRA-123" is approved by "jim@fundingcircle.com" at "2014-10-05 17:30:10"

  And snapshots are regenerated

  When I visit feature review "FR_123" as at "2014-10-04 15:00:00"
  Then I should see that the Feature Review was not approved
  Then I should see the tickets
    | Ticket   | Summary       | Status      |
    | JIRA-123 | Urgent ticket | In Progress |

  When I visit feature review "FR_123" as at "2014-10-06 10:00:00"
  Then I should see that the Feature Review was approved at "2014-10-05 17:30:10"
  And I should see the tickets
    | Ticket   | Summary       | Status               |
    | JIRA-123 | Urgent ticket | Ready for Deployment |

Scenario: QA rejects feature
  Given an application called "frontend"
  And an application called "backend"
  And a commit "#abc" by "Alice" is created at "2014-10-04 13:05:00" for app "frontend"
  And a commit "#def" by "Alice" is created at "2014-10-04 13:05:00" for app "backend"
  And I am logged in as "foo@bar.com"
  And developer prepares review known as "FR_qa_rejects" with apps
    | app_name | version |
    | frontend | #abc    |
    | backend  | #def    |
  When I visit the feature review known as "FR_qa_rejects"
  Then I should see the QA acceptance with heading "warning"

  When I "reject" the feature with comment "Not good enough" as a QA

  Then I should see an alert: "Thank you for your submission. It will appear in a moment."

  When I reload the page after a while
  Then I should see the QA acceptance
    | status  | email       | comment         |
    | danger  | foo@bar.com | Not good enough |

  When I "accept" the feature with comment "Superb!" as a QA

  And I reload the page after a while
  Then I should see the QA acceptance
    | status  | email       | comment         |
    | danger  | foo@bar.com | Not good enough |
    | success | foo@bar.com | Superb!         |

Scenario: QA has approved previous commit
  Given an application called "frontend"
  And a commit "#initial" by "Bob" is created at "2017-08-24 08:00:00" for app "frontend"
  And the branch "new-branch" is checked out
  And the branch "new-branch" is merged with merge commit "#merge1" at "2017-08-24 09:00:00"
  And a commit "#abc" by "Alice" is created at "2017-08-24 10:00:00" for app "frontend"
  And a commit "#def" by "Alice" is created at "2017-08-24 11:00:00" for app "frontend"
  And I am logged in as "foo@bar.com"
  And developer prepares review known as "review1" with apps
    | app_name | version |
    | frontend | #abc    |
  And developer prepares review known as "review2" with apps
    | app_name | version |
    | frontend | #def    |

  When I visit the feature review known as "review1"
  Then I should see the QA acceptance with heading "warning"
  When I "accept" the feature with comment "All good" as a QA
  Then I should see an alert: "Thank you for your submission. It will appear in a moment."
  When I reload the page after a while
  Then I should see the QA acceptance
    | status   | email       | comment  |
    | success  | foo@bar.com | All good |

  When I visit the feature review known as "review2"
  Then I should see the QA acceptance
    | status   | email       | comment  |
    | success  | foo@bar.com | All good |
  When I "reject" the feature with comment "Needs improvements" as a QA
  Then I should see an alert: "Thank you for your submission. It will appear in a moment."
  When I reload the page after a while
  Then I should see the QA acceptance
    | status   | email       | comment            |
    | success  | foo@bar.com | All good           |
    | danger   | foo@bar.com | Needs improvements |

Scenario: Repo Owner approves feature
  Given an application with owner "foo@bar.com" called "frontend"
  And an application with owner "foo@bar.com" called "backend"
  And a commit "#abc" by "Alice" is created at "2014-10-04 13:05:00" for app "frontend"
  And a commit "#def" by "Alice" is created at "2014-10-04 13:05:00" for app "backend"
  And I am logged in as "foo@bar.com"
  And developer prepares review known as "FR_repo_owner_test" with apps
    | app_name | version |
    | frontend | #abc    |
    | backend  | #def    |

  When I visit the feature review known as "FR_repo_owner_test"
  Then I should see the Repo Owner Commentary with heading "warning"
  When I "reject" the feature with comment "Not good enough" as a Repo Owner
  Then I should see an alert: "Thank you for your submission. It will appear in a moment."
  When I reload the page after a while
  Then all pull requests for "2" application should be updated to "pending" status
  Then I should see the Repo Owner Commentary
    | status | email       | comment         |
    | danger | foo@bar.com | Not good enough |

  When I "approve" the feature with comment "This can go live!" as a Repo Owner
  And I reload the page after a while
  Then all pull requests for "2" application should be updated to "success" status
  Then I should see the Repo Owner Commentary
    | status  | email       | comment           |
    | success | foo@bar.com | This can go live! |
