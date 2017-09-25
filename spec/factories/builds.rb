# frozen_string_literal: true
FactoryGirl.define do
  factory :unit_test_build, class: Build do
    build_type 'unit'
  end

  factory :integration_test_build, class: Build do
    build_type 'integration'
  end
end
