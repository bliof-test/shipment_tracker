require 'deploy'
require 'deploy_alert'
require 'slack/notifications'

class DeployAlertJob < ActiveJob::Base
  queue_as :default

  def perform(deploy_attrs)
    old_deploy = Deploy.new(deploy_attrs[:old_deploy])
    new_deploy = Deploy.new(deploy_attrs[:new_deploy])
    message = DeployAlert.audit(old_deploy, new_deploy)
    return unless message
    Rails.logger.warn message
    SlackNotifier.send(message, ShipmentTracker::DEPLOY_ALERT_SLACK_CHANNEL)
  end
end
