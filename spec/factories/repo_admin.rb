# frozen_string_literal: true
FactoryBot.define do
  factory :repo_admin do
    name 'Foo'
    email { |n| "foo#{n}@bar.baz" }
  end
end
