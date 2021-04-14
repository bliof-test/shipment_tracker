# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoLinkTicketJob do
  include ActiveJob::TestHelper

  describe '#perform' do
    subject(:job) {
      described_class.perform_later(
        head_sha: 'abc123',
        repo_name: 'my-repo',
        branch_name: branch_name,
        title: title,
      )
    }

    let(:branch_name) { 'branch-name' }
    let(:title) { 'A Cool Title' }

    it 'queues the job' do
      expect { job }
        .to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end

    context 'when there is no ticket name in the branch name or title' do
      let(:branch_name) { 'branch-name' }
      let(:title) { 'A Cool Title' }

      it 'does not attempt to link a ticket' do
        expect(LinkTicket).not_to receive(:run)
        perform_enqueued_jobs { job }
      end
    end

    context 'when there is a ticket name at the start of the branch name' do
      let(:branch_name) { 'TEST-101-branch-name' }

      it 'attempts to link the ticket' do
        expect(LinkTicket).to receive(:run).with(hash_including(jira_key: 'TEST-101'))
        perform_enqueued_jobs { job }
      end
    end

    context 'when there is a ticket name in the middle of the branch name' do
      let(:branch_name) { 'abc-TEST-102-branch-name' }

      it 'attempts to link the ticket' do
        expect(LinkTicket).to receive(:run).with(hash_including(jira_key: 'TEST-102'))
        perform_enqueued_jobs { job }
      end
    end

    context 'when there is a lower-case ticket name in the branch name' do
      let(:branch_name) { 'test-101-branch-name' }

      it 'does not attempt to link the ticket' do
        expect(LinkTicket).not_to receive(:run)
        perform_enqueued_jobs { job }
      end
    end

    context 'when there is a ticket name in the branch name and title' do
      let(:branch_name) { 'TEST-104-branch-name' }
      let(:title) { '[TEST-104] A Cool Title' }

      it 'attempts to link the ticket from the branch name' do
        expect(LinkTicket).to receive(:run).with(hash_including(jira_key: 'TEST-104'))
        perform_enqueued_jobs { job }
      end
    end

    context 'when there is a ticket name in the title' do
      let(:title) { '[TEST-105] A Cool Title' }

      it 'attempts to link the ticket' do
        expect(LinkTicket).to receive(:run).with(hash_including(jira_key: 'TEST-105'))
        perform_enqueued_jobs { job }
      end
    end

    context 'when there is a lower-case ticket name in the title' do
      let(:title) { '[test-101] A Cool Title' }

      it 'does not attempt to link the ticket' do
        expect(LinkTicket).not_to receive(:run)
        perform_enqueued_jobs { job }
      end
    end
  end
end
