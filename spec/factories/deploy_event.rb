require 'events/deploy_event'

FactoryGirl.define do
  factory :deploy_event, class: Events::DeployEvent do
    transient do
      server 'uat.example.com'
      sequence(:version) { |n| "abc#{n}" }
      app_name 'hello_world'
      locale 'us'
      deployed_at { Time.now.utc.to_i }
      deployed_by 'frank@example.com'
      environment 'uat'
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

    initialize_with { new(attributes) }
  end
end
