# frozen_string_literal: true

require 'events/deploy_alert_event'

FactoryBot.define do
  factory :deploy_alert_event, class: Events::DeployAlertEvent do
    transient do
      uuid { SecureRandom.uuid }
      message { 'Deploy alert from factory.' }
    end

    details {
      {
        'deploy_uuid' => uuid,
        'message' => message,
      }
    }

    initialize_with { new(attributes) }
  end
end
