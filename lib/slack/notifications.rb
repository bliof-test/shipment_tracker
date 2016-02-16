require 'slack-notifier'

class SlackNotifier
  @@notifier = Slack::Notifier.new(ENV.fetch('SLACK_WEBHOOK'))

  def self.send(msg, channel)
    @@notifier.channel = channel
    @@notifier.ping(msg, link_names: 1)
  end
end
