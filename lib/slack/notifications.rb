require 'slack-notifier'

class SlackNotifier
  def self.send(msg, channel)
    @notifier ||= Slack::Notifier.new(ShipmentTracker::SLACK_WEBHOOK)
    @notifier.channel = prepend_hash(channel)
    @notifier.ping(attachment_for(msg), link_names: 1)
  end

  def self.attachment_for(msg)
    {
      fallback: msg,
      text: msg,
      color: 'danger',
    }
  end
  private_class_method :attachment_for

  def self.prepend_hash(channel)
    channel.start_with?('#') ? channel : channel.prepend('#')
  end
  private_class_method :prepend_hash
end
