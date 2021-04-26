# frozen_string_literal: true

require 'slack-ruby-client'

class SlackClient
  def self.send_deploy_alert(msg, releases_link, app_name, deployer)
    client = DeployAlertClient.slack_client
    attachments = format_alert_msg(msg, releases_link, app_name, deployer)
    client.send_with_attachments(attachments)
  end

  def initialize(token, channel)
    @channel = channel
    Slack.configure do |config|
      config.token = token
    end
    @notifier = Slack::Web::Client.new
    @notifier.auth_test
  end

  def send_with_attachments(attachments)
    notifier.chat_postMessage(channel: channel, attachments: attachments, as_user: true)
  end

  private

  attr_reader :notifier, :channel

  def self.format_alert_msg(msg, releases_link, app_name, deployer)
    [
      {
        'fallback': msg,
        'title': 'Deploy Alert',
        'title_link': releases_link,
        'text': msg,
        'color': 'danger',
        'fields': [
          { 'title': 'Project', 'value': app_name, 'short': true },
          { 'title': 'Deployer', 'value': deployer, 'short': true },
        ],
      },
    ]
  end
  private_class_method :format_alert_msg
end
