# frozen_string_literal: true
require 'rails_helper'
require 'unlink_ticket'

RSpec.describe UnlinkTicket do
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

  describe '.class' do
    subject(:unlink_comment) { described_class.run(args) }

    context 'the ticket ID is an invalid format' do
      let(:jira_key) { 'INVALID' }
      let(:expected_message) {
        "Failed to unlink #{jira_key}. Please check that the ticket ID is correct."
      }

      it 'fails validation' do
        result = subject
        expect(result).to fail_with(:invalid_key)
        expect(result.value.message).to eq(expected_message)
      end
    end

    context 'the ticket ID is a valid format' do
      let(:jira_key) { 'JIRA-123' }

      context 'when the ticket is not linked' do
        let(:expected_message) { "Failed to unlink #{jira_key}. Existing link couldn't be found." }

        before do
          allow(JiraClient).to receive(:post_comment).and_raise(StandardError)
        end

        it 'fails with message' do
          expect(subject).to fail_with(:missing_key)
          expect(subject.value.message).to eq(expected_message)
        end
      end

      context 'when the ticket is linked' do
        context 'when posting returns an error' do
          let(:expected_message) { "Failed to unlink #{jira_key}. Something went wrong." }
          let(:ticket) { Ticket.new(paths: [feature_review_path(apps_with_versions)], key: jira_key) }

          before do
            allow(JiraClient).to receive(:post_comment).and_raise(StandardError)
            allow(ticket_repository).to receive(:tickets_for_path).and_return([ticket])
          end

          it 'fails with message' do
            expect(subject).to fail_with(:post_failed)
            expect(subject.value.message).to eq(expected_message)
          end
        end

        context 'when posting is successful' do
          let(:expected_message) {
            "Feature Review was unlinked from #{jira_key}."\
              ' Refresh this page in a moment and the ticket will disappear.'
          }
          let(:ticket) { Ticket.new(paths: [feature_review_path(apps_with_versions)], key: jira_key) }

          before do
            allow(ticket_repository).to receive(:tickets_for_path).and_return([ticket])
          end

          it 'sends a message to Jira' do
            expect(JiraClient).to receive(:post_comment).with(jira_key, a_kind_of(String))

            subject
          end

          it 'returns status update message' do
            expect(subject).to be_a_success
            expect(subject.value).to eq(expected_message)
          end
        end
      end
    end
  end
end
