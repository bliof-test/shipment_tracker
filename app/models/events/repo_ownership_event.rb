# frozen_string_literal: true
require 'events/base_event'

module Events
  class RepoOwnershipEvent < Events::BaseEvent
    def app_name
      details.fetch('app_name')
    end

    def repo_owners
      details['repo_owners']
    end
  end
end
