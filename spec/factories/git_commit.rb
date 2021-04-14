# frozen_string_literal: true

require 'git_commit'

FactoryBot.define do
  factory :git_commit do
    sequence(:id) { |n| "abc#{n}" }
    author_name { 'Frank' }
    message { 'A commit' }

    initialize_with { new(attributes) }
  end
end
