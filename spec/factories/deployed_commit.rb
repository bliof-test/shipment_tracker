# frozen_string_literal: true
require 'deployed_commit'

FactoryGirl.define do
  factory :deployed_commit do
    sha 'abc'
    app_name 'test_app'
    merged_by 'Frank'
    deploys []

    initialize_with { new(attributes) }
  end
end
