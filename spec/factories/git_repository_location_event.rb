# frozen_string_literal: true
require 'events/git_repository_location_event'

FactoryGirl.define do
  factory :git_repository_location_event, class: Events::GitRepositoryLocationEvent do
    transient do
      app_name 'test-app'
      required_checks []
    end

    details {
      {
        'app_name' => app_name,
        'required_checks' => required_checks,
      }
    }

    initialize_with { new(attributes) }
  end
end
