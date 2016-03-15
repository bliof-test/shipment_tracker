# frozen_string_literal: true
require 'slack-notifier'

class SlackClient
  def self.send_deploy_alert(msg, releases_link, app_name, deployer)
    client = DeployAlertClient.slack_client
    attachments = format_alert_msg(msg, releases_link, app_name, deployer)
    client.send_with_attachments(attachments)
  end

  def initialize(webhook, channel)
    @notifier = Slack::Notifier.new(webhook)
    notifier.channel = prepend_hash(channel)
    self
  end

  def send_with_attachments(attachments)
    notifier.ping(attachments: attachments, link_names: 1)
  end

  private

  attr_reader :notifier

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

  def prepend_hash(channel)
    channel.start_with?('#') ? channel : "##{channel}"
  end
end
