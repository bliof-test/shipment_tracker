# frozen_string_literal: true
require 'snapshots/repo_ownership'

FactoryGirl.define do
  factory :git_repository_location_snapshot, class: Snapshots::GitRepositoryLocation do
    name 'test-app'
    required_checks []
  end
end
