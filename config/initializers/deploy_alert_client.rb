# frozen_string_literal: true

require 'clients/slack'

class DeployAlertClient
  def self.slack_client
    @slack_client ||= SlackClient.new(
      ENV.fetch('SLACK_WEBHOOK', 'http://localhost'),
      ENV.fetch('DEPLOY_ALERT_SLACK_CHANNEL', 'general'),
    )
  end
end
