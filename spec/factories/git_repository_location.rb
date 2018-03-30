# frozen_string_literal: true

FactoryBot.define do
  factory :git_repository_location do
    name { |n| "Black Pearl #{n}" }
    uri { |n| "https://github.com/FundingCircle/shipment_tracker-#{n}.git" }
  end
end
