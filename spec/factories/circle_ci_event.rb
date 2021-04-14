# frozen_string_literal: true

require 'events/circle_ci_event'

FactoryBot.define do
  factory :circle_ci_event, class: Events::CircleCiEvent do
    transient do
      success? { true }
      sequence :version
      build_url { 'http://example.com' }
      build_type { 'unit' }
      app_name { 'abc' }
    end

    details {
      {
        'payload' => {
          'app_name' => app_name,
          'outcome' => success? ? 'success' : 'failed',
          'vcs_revision' => version,
          'build_url' => build_url,
          'build_type' => build_type,
        },
      }
    }

    initialize_with { new(attributes) }
  end
end
