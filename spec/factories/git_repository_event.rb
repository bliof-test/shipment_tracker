# frozen_string_literal: true
require 'events/git_repository_location_event'

FactoryBot.define do
  factory :git_repository_location_event, class: Events::GitRepositoryLocationEvent do
    transient do
      app_name 'test-app'
      audit_options []
    end

    details {
      {
        'app_name' => app_name,
        'audit_options' => audit_options,
      }
    }

    initialize_with { new(attributes) }
  end
end
