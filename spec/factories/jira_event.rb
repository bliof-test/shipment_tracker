# frozen_string_literal: true

require 'events/jira_event'

FactoryBot.define do
  factory :jira_event, class: Events::JiraEvent do
    transient do
      sequence(:issue_id)
      sequence(:key) { |n| "JIRA-#{n}" }

      summary { '' }
      description { '' }
      display_name { 'joe' }
      user_email { 'joe.bloggs@example.com' }
      assignee_email { 'joe.assignee@example.com' }
      status { 'To Do' }
      updated { '2015-05-07T15:24:34.957+0100' }
      comment_body { nil }

      changelog_details { {} }

      default_details do
        {
          'webhookEvent' => 'jira:issue_updated',
          'user' => {
            'displayName' => display_name,
            'emailAddress' => user_email,
          },
          'issue' => {
            'id' => issue_id,
            'key' => key,
            'fields' => {
              'summary' => summary,
              'description' => description,
              'status' => { 'name' => status },
              'updated' => updated,
              'assignee' => {
                'emailAddress' => assignee_email,
              },
            },
          },
        }
      end
    end

    details do
      details = default_details.merge(changelog_details)
      details['comment'] = { 'body' => comment_body } if comment_body
      details
    end

    initialize_with { new(attributes) }

    trait :todo do
      status { 'To Do' }
    end

    trait :in_progress do
      status { 'In Progress' }
    end

    trait :ready_for_review do
      status { 'Ready For Review' }
    end

    trait :ready_for_deploy do
      status { 'Ready for Deployment' }
    end

    trait :done do
      status { 'Done' }
    end

    trait :created do
      todo
    end

    trait :started do
      changelog_details {
        {
          'changelog' => {
            'items' => [
              {
                'field' => 'status',
                'fromString' => 'To Do',
                'toString' => 'In Progress',
              },
            ],
          },
        }
      }
      in_progress
    end

    trait :development_completed do
      changelog_details {
        {
          'changelog' => {
            'items' => [
              {
                'field' => 'status',
                'fromString' => 'In Progress',
                'toString' => 'Ready For Review',
              },
            ],
          },
        }
      }
      ready_for_review
    end

    trait :rejected do
      changelog_details {
        {
          'changelog' => {
            'items' => [
              {
                'field' => 'status',
                'fromString' => 'Ready for Review',
                'toString' => 'In Progress',
              },
            ],
          },
        }
      }
      in_progress
    end

    trait :approved do
      changelog_details {
        {
          'changelog' => {
            'items' => [
              {
                'field' => 'status',
                'fromString' => 'Ready For Review',
                'toString' => 'Ready for Deployment',
              },
            ],
          },
        }
      }
      ready_for_deploy
    end

    trait :deployed do
      changelog_details {
        {
          'changelog' => {
            'items' => [
              {
                'field' => 'status',
                'fromString' => 'Ready for Deployment',
                'toString' => 'Done',
              },
            ],
          },
        }
      }
      done
    end

    trait :unapproved do
      changelog_details {
        {
          'changelog' => {
            'items' => [
              {
                'field' => 'status',
                'fromString' => 'Ready for Deployment',
                'toString' => 'In Progress',
              },
            ],
          },
        }
      }
      in_progress
    end

    trait :moved do
      changelog_details {
        {
          'changelog' => {
            'items' => [
              {
                'field' => 'Key',
                'fromString' => 'ONEJIRA-1',
                'toString' => 'TWOJIRA-2',
              },
            ],
          },
        }
      }
      todo
    end
  end

  factory :jira_event_user_created, class: Events::JiraEvent do
    details do
      {
        'timestamp' => 1_434_031_799_536,
        'webhookEvent' => 'user_created',
        'user' => {
          'self' => 'https://jira.example.com/rest/api/2/user?key=john.doe%40example.com',
          'name' => 'john.doe@example.com',
          'key' => 'john.doe@example.com',
          'emailAddress' => 'john.doe@example.com',
          'displayName' => 'John Doe',
        },
      }
    end
  end
end
