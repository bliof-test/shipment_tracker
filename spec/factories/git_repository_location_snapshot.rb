# frozen_string_literal: true

FactoryBot.define do
  factory :git_repository_location_snapshot, class: Snapshots::GitRepositoryLocation do
    name 'test-app'
    audit_options []
  end
end
