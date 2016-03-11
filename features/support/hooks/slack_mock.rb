require 'slack/notifications'

Before('@mock_slack_notifier') do
  allow(SlackNotifier).to receive(:send)
end
