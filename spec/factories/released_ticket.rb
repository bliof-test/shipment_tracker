# frozen_string_literal: true

require 'released_ticket'

FactoryBot.define do
  factory :released_ticket do
    sequence(:key) { |n| "DS-#{n}" }
    summary { 'Example summary' }
    description { 'Short description' }
    versions {
      %w[7ff5be8830d3835cb06c24040d39da52147e4bdd
         0000000000000000000000000000000000000000
         d1f55c79a8f16c7f751fc8dca5fe3c5a97994e4b]
    }
    deploys {
      [{
        'app' => 'hello_world_rails',
        'deployed_at' => '2016-03-10 18:06 UTC',
        'github_url' => 'https://github.com/FundingCircle/hello_world_rails',
        'region' => 'gb',
        'version' => '63c504b1cc3ccd19a079e4ea2477809ff503a7af',
      }]
    }

    initialize_with { new(attributes) }
  end
end
