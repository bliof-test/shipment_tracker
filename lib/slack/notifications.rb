require 'slack-notifier'

class SlackNotifier
  def self.send(msg, channel)
    @notifier ||= Slack::Notifier.new(ENV.fetch('SLACK_WEBHOOK'))
    @notifier.channel = channel
    @notifier.ping(msg, link_names: 1)
  end
end
