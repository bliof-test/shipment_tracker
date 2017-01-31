# frozen_string_literal: true
require 'events/release_exception_event'

FactoryGirl.define do
  factory :release_exception_event, class: Events::ReleaseExceptionEvent do
    transient do
      approved true
      email 'test@example.com'
      comment 'LGTM'
      apps('frontend' => 'abc')
    end

    details {
      {
        status: approved ? 'approved' : 'declined',
        email: email,
        comment: comment,
        apps: apps.map { |name, version| { name: name, version: version } },
      }
    }

    initialize_with { new(attributes) }
  end
end
