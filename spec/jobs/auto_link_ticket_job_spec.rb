# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoLinkTicketJob do
  describe '#perform' do
    let(:args) {
      {
        head_sha: 'abc123',
        repo_name: 'my-repo',
        branch_name: branch_name,
        title: title,
      }
    }
    let(:branch_name) { 'branch-name' }
    let(:title) { 'A Cool Title' }

    context 'when there is no ticket name in the branch name or title' do
      let(:branch_name) { 'branch-name' }
      let(:title) { 'A Cool Title' }

      it 'does not attempt to link a ticket' do
        expect(LinkTicket).not_to receive(:run)
        described_class.perform_later(args)
      end
    end

    context 'when there is a ticket name at the start of the branch name' do
      let(:branch_name) { 'TEST-101-branch-name' }

      it 'attempts to link the ticket' do
        expect(LinkTicket).to receive(:run).with(hash_including(jira_key: 'TEST-101'))
        described_class.perform_later(args)
      end
    end

    context 'when there is a ticket name in the middle of the branch name' do
      let(:branch_name) { 'abc-TEST-101-branch-name' }

      it 'attempts to link the ticket' do
        expect(LinkTicket).to receive(:run).with(hash_including(jira_key: 'TEST-101'))
        described_class.perform_later(args)
      end
    end

    context 'when there is a lower-case ticket name in the branch name' do
      let(:branch_name) { 'test-101-branch-name' }

      it 'does not attempt to link the ticket' do
        expect(LinkTicket).not_to receive(:run)
        described_class.perform_later(args)
      end
    end

    context 'when there is a ticket name in the branch name and title' do
      let(:branch_name) { 'TEST-101-branch-name' }
      let(:title) { '[TEST-102] A Cool Title' }

      it 'attempts to link the ticket from the branch name' do
        expect(LinkTicket).to receive(:run).with(hash_including(jira_key: 'TEST-101'))
        described_class.perform_later(args)
      end
    end

    context 'when there is a ticket name in the title' do
      let(:title) { '[TEST-101] A Cool Title' }

      it 'attempts to link the ticket' do
        expect(LinkTicket).to receive(:run).with(hash_including(jira_key: 'TEST-101'))
        described_class.perform_later(args)
      end
    end

    context 'when there is a lower-case ticket name in the title' do
      let(:title) { '[test-101] A Cool Title' }

      it 'does not attempt to link the ticket' do
        expect(LinkTicket).not_to receive(:run)
        described_class.perform_later(args)
      end
    end
  end
end
