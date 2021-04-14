# frozen_string_literal: true

require 'events/manual_test_event'

FactoryBot.define do
  factory :manual_test_event, class: Events::ManualTestEvent do
    transient do
      accepted { true }
      email { 'alice@example.com' }
      comment { 'LGTM' }
      apps { { 'frontend' => 'abc' } }
    end

    details {
      {
        status: accepted ? 'success' : 'failed',
        email: email,
        comment: comment,
        apps: apps.map { |name, version| { name: name, version: version } },
      }
    }

    initialize_with { new(attributes) }
  end
end
