require 'slack-notifier'

class SlackNotifier
  def initialize
    @notifier = Slack::Notifier.new ENV['SLACK_WEB_HOOK']
  end

  def send(msg, channel)
    @notifier.channel = channel
    @notifier.ping(msg, link_names: 1)
  end
end
