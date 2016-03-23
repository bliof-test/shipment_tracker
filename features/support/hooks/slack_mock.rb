# frozen_string_literal: true
require 'clients/slack'

Before('@mock_slack_notifier') do
  allow(SlackClient).to receive(:send_deploy_alert)
end
