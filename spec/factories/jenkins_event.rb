require 'events/jenkins_event'

FactoryGirl.define do
  factory :jenkins_event, class: Events::JenkinsEvent do
    transient do
      success? true
      sequence(:version)
    end

    details {
      {
        'build' => {
          'scm' => {
            'commit' => version,
          },
          'status' => success? ? 'SUCCESS' : 'FAILURE',
        },
      }
    }

    initialize_with { new(attributes) }
  end
end
