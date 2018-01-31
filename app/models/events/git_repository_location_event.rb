# frozen_string_literal: true
require 'events/base_event'

module Events
  class GitRepositoryLocationEvent < Events::BaseEvent
    def app_name
      details.fetch('app_name')
    end

    def audit_options
      details.fetch('audit_options', [])
    end
  end
end
