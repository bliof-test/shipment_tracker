# frozen_string_literal: true

require 'rails_helper'
require 'link_ticket'

RSpec.describe LinkTicket do
  let(:ticket_repository) { instance_double(Repositories::TicketRepository) }

  let(:apps_with_versions) { { 'frontend' => 'abc', 'backend' => 'def' } }
  let(:args) {
    {
      jira_key: jira_key,
      feature_review_path: feature_review_path(apps_with_versions),
      root_url: 'http://test.com/',
    }
  }

  before do
    allow(Repositories::TicketRepository).to receive(:new).and_return(ticket_repository)
    allow(ticket_repository).to receive(:tickets_for_path).and_return([])
    allow(JiraClient).to receive(:post_comment)
  end

  context 'when valid ticket ID format' do
    let(:jira_key) { 'JIRA-123' }

    context 'when not linked yet' do
      let(:expected_message) {
        "Feature Review was linked to #{jira_key}. Refresh this page in a moment and the ticket will appear."
      }
      let(:expected_comment) {
        "[Feature ready for review|http://test.com#{feature_review_path(apps_with_versions)}]"
      }

      it 'posts a comment' do
        expect(JiraClient).to receive(:post_comment).with(jira_key, expected_comment)
        described_class.run(args)
      end

      it 'returns a success message' do
        result = described_class.run(args)
        expect(result).to be_a_success
        expect(result.value).to eq(expected_message)
      end
    end

    context 'when ticket ID can not be found' do
      let(:expected_message) {
        "Failed to link #{jira_key}. Please check that the ticket ID is correct."
      }
      before do
        allow(JiraClient).to receive(:post_comment).and_raise(JiraClient::InvalidKeyError)
      end
      it 'fails with message' do
        result = described_class.run(args)
        expect(result).to fail_with(:invalid_key)
        expect(result.value.message).to eq(expected_message)
      end
    end

    context 'when ticket is already linked' do
      let(:expected_message) {
        "Failed to link #{jira_key}. Duplicate tickets should not be added."
      }
      let(:ticket) { Ticket.new(paths: [feature_review_path(apps_with_versions)], key: jira_key) }

      before do
        allow(ticket_repository).to receive(:tickets_for_path).and_return([ticket])
      end

      it 'fails with message' do
        result = described_class.run(args)
        expect(result).to fail_with(:duplicate_key)
        expect(result.value.message).to eq(expected_message)
      end
    end

    context 'when posting returns an error' do
      let(:expected_message) { "Failed to link #{jira_key}. Something went wrong." }

      before do
        allow(JiraClient).to receive(:post_comment).and_raise(StandardError)
      end

      it 'fails with message' do
        result = described_class.run(args)
        expect(result).to fail_with(:post_failed)
        expect(result.value.message).to eq(expected_message)
      end
    end
  end

  context 'when invalid ticket ID format' do
    let(:jira_key) { 'INVALID' }
    let(:expected_message) {
      "Failed to link #{jira_key}. Please check that the ticket ID is correct."
    }

    it 'fails validation' do
      result = described_class.run(args)
      expect(result).to fail_with(:invalid_key)
      expect(result.value.message).to eq(expected_message)
    end
  end
end
