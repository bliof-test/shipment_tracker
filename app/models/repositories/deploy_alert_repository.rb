# frozen_string_literal: true
require 'events/deploy_alert_event'
require 'snapshots/deploy'

module Repositories
  class DeployAlertRepository < Base
    def initialize(store = Snapshots::Deploy)
      @store = store
    end

    def apply(event)
      return unless event.is_a?(Events::DeployAlertEvent)

      deploy = store.find_by!(uuid: event.deploy_uuid)
      deploy.deploy_alert = event.message
      deploy.save!
    end
  end
end
