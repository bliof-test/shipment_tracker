require 'events/circle_ci_event'

FactoryGirl.define do
  factory :circle_ci_event, class: Events::CircleCiEvent do
    transient do
      success? true
      sequence(:version)
    end

    details {
      {
        'payload' => {
          'outcome' => success? ? 'success' : 'failed',
          'vcs_revision' => version,
        },
      }
    }

    initialize_with { new(attributes) }
  end
end
