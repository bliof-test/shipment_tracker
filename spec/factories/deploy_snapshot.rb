# frozen_string_literal: true

require 'snapshots/deploy'

FactoryBot.define do
  factory :deploy_snapshot, class: Snapshots::Deploy do
    server { 'uat.example.com' }
    sequence(:version) { |n| "#{n}abcabcabcabcabcabcabcabcabcabcabcabcabc"[0..39] }
    app_name { 'hello_world' }
    region { 'us' }
    deployed_at { Time.now.utc.to_i }
    deployed_by { 'frank@example.com' }
    environment { 'uat' }
    deploy_alert { nil }
    uuid { nil }
  end
end
