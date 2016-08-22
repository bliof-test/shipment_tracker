# frozen_string_literal: true
require 'merge'

FactoryGirl.define do
  factory :merge do
    sha 'abc'
    app_name 'test_app'
    merged_by 'Frank'
    deploys []

    initialize_with { new(attributes) }
  end
end
