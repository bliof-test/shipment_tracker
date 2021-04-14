# frozen_string_literal: true

require 'events/jenkins_event'

FactoryBot.define do
  factory :jenkins_event, class: Events::JenkinsEvent do
    transient do
      success? { true }
      sequence :version
      build_url { 'http://example.com' }
      build_type { 'unit' }
      app_name { 'abc' }
    end

    details {
      {
        'build' => {
          'app_name' => app_name,
          'full_url' => build_url,
          'scm' => {
            'commit' => version,
          },
          'status' => success? ? 'SUCCESS' : 'FAILURE',
          'build_type' => build_type,
        },
      }
    }

    initialize_with { new(attributes) }
  end
end
