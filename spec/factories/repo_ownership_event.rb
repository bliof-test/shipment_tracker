# frozen_string_literal: true

require 'events/repo_ownership_event'

FactoryBot.define do
  factory :repo_ownership_event, class: Events::RepoOwnershipEvent do
    transient do
      app_name { 'test-app' }
      repo_owners { '' }
    end

    details {
      {
        'app_name' => app_name,
        'repo_owners' => repo_owners,
      }
    }

    initialize_with { new(attributes) }
  end
end
