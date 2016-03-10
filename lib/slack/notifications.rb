require 'slack-notifier'

class SlackNotifier
  def self.send(msg, channel)
    @notifier ||= Slack::Notifier.new(ENV.fetch('SLACK_WEBHOOK'))
    @notifier.channel prepend_hash(channel)
    @notifier.ping(msg, link_names: 1)
  end

  private

  def prepend_hash(channel)
    channel.start_with?('#') ? channel : channel.prepend('#')
  end
end
