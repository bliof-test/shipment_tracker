require 'slack-notifier'

class SlackNotifier
  def self.send(msg, channel)
    @notifier ||= Slack::Notifier.new(ShipmentTracker::SLACK_WEBHOOK)
    @notifier.channel = prepend_hash(channel)
    @notifier.ping(msg, link_names: 1)
  end

  def self.prepend_hash(channel)
    channel.start_with?('#') ? channel : "##{channel}"
  end
  private_class_method :prepend_hash
end
