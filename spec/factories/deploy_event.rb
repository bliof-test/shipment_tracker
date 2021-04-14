# frozen_string_literal: true

require 'events/deploy_event'

FactoryBot.define do
  factory :deploy_event, class: Events::DeployEvent do
    transient do
      server { 'uat.example.com' }
      sequence(:version) { |n| "#{n}abcabcabcabcabcabcabcabcabcabcabcabcabc"[0..39] }
      app_name { 'hello_world' }
      locale { 'us' }
      deployed_at { Time.now.utc.to_i }
      deployed_by { 'frank@example.com' }
      environment { 'uat' }
    end

    details {
      {
        'server' => server,
        'version' => version,
        'app_name' => app_name,
        'locale' => locale,
        'deployed_at' => deployed_at,
        'deployed_by' => deployed_by,
        'environment' => environment,
      }
    }

    uuid { nil }

    initialize_with { new(attributes) }
  end
end
