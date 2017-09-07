# frozen_string_literal: true
require 'events/base_event'

module Events
  class GitRepositoryLocationEvent < Events::BaseEvent
    def app_name
      details.fetch('app_name')
    end

    def required_checks
      details.fetch('required_checks', [])
    end
  end
end
