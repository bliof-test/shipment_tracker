require 'deploy'
require 'deploy_alert'
require 'slack/notifications'

class DeployAlertJob < ActiveJob::Base
  queue_as :default

  def perform(deploy_attrs)
    current_deploy = Deploy.new(deploy_attrs[:current_deploy])
    previous_deploy = Deploy.new(deploy_attrs[:previous_deploy]) if deploy_attrs[:previous_deploy]

    message = DeployAlert.audit_message(current_deploy, previous_deploy)
    SlackNotifier.send(message, ShipmentTracker::DEPLOY_ALERT_SLACK_CHANNEL) if message
  end
end
