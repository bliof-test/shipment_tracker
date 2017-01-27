# frozen_string_literal: true
require 'events/base_event'

module Events
  class DeployAlertEvent < Events::BaseEvent
    def deploy_uuid
      details['deploy_uuid']
    end

    def message
      details['message']
    end
  end
end
