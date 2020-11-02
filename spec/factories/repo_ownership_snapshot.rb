# frozen_string_literal: true

require 'snapshots/repo_ownership'

FactoryBot.define do
  factory :repo_ownership_snapshot, class: Snapshots::RepoOwnership do
    app_name { 'test-app' }
    repo_owners { '' }
  end
end
