require 'rails_helper'
require 'clients/slack'

RSpec.describe SlackClient do
  before do
    allow_any_instance_of(Slack::Notifier).to receive(:ping)
  end

  describe '.send_deploy_alert' do
    let(:client) { double }
    let(:expected_attachment) {
      [
        { fallback: 'alert message',
          title: 'Deploy Alert',
          title_link: 'http://example.com',
          text: 'alert message',
          color: 'danger',
          fields: [
            { title: 'Project', value: 'frontend', short: true },
            { title: 'Deployer', value: 'Jeff', short: true },
          ],
        },
      ]
    }

    before do
      allow(DeployAlertClient).to receive(:slack_client).and_return(client)
    end

    it 'sends a message as attachment' do
      expect(client).to receive(:send_with_attachments).with(expected_attachment)
      SlackClient.send_deploy_alert('alert message', 'http://example.com', 'frontend', 'Jeff')
    end
  end

  describe '#send_with_attachments' do
    subject(:client) { SlackClient.new(webhook, channel) }
    let(:notifier) { double(:notifier).as_null_object }
    let(:attachments) { double }
    let(:webhook) { double }
    let(:channel) { 'double' }

    before do
      allow(Slack::Notifier).to receive(:new).and_return(notifier)
    end
    it 'pings the notififier with the given attachments' do
      client.send_with_attachments(attachments)
      expect(notifier).to have_received(:ping).with(attachments: attachments, link_names: 1)
    end

    it 'posts to the correct channel' do
      client.send_with_attachments(attachments)
      expect(Slack::Notifier).to have_received(:new).with(webhook)
      expect(notifier).to have_received(:channel=).with('#double')
    end
  end
end
