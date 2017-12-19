# frozen_string_literal: true
FactoryGirl.define do
  factory :repo_admin do
    name 'Foo'
    email { |n| "foo#{n}@bar.baz" }
  end
end
