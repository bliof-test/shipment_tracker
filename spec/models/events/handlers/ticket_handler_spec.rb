# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Events::Handlers::TicketHandler do
  describe '#apply' do
    let(:time) { Time.current.change(usec: 0) }
    let(:ticket_defaults) { { paths: [path], versions: %w(foo), version_timestamps: { 'foo' => nil } } }
    let(:url) { feature_review_url(app: 'foo') }
    let(:path) { feature_review_path(app: 'foo') }

    it 'updates key information' do
      ticket = {}
      created_ticket_event = build(:jira_event, :created, key: 'JIRA-1', summary: 'work 1', created_at: time + 1.hour)

      new_ticket = described_class.new(ticket, created_ticket_event).apply

      expect(new_ticket).to include(
        'key' => 'JIRA-1',
        'summary' => 'work 1',
        'status' => 'To Do',
        'event_created_at' => time + 1.hour,
        'approved_at' => nil,
      )
    end

    context 'when the event is approval' do
      it 'updates approved_at with events created_at' do
        ticket = {}
        created_ticket_event = build(
          :jira_event,
          :approved,
          created_at: time + 1.hour,
        )

        new_ticket = described_class.new(ticket, created_ticket_event).apply

        expect(new_ticket).to include('approved_at' => time + 1.hour, 'approved_by_email' => 'joe.bloggs@example.com')
      end
    end

    context 'when ticket is present and event is PAST approval' do
      it 'uses approved_at from previous event' do
        ticket = { 'approved_at' => 123, 'approved_by_email' => 'joe.bloggs@example.com' }
        created_ticket_event = build(:jira_event, :deployed, created_at: time + 1.hour)

        new_ticket = described_class.new(ticket, created_ticket_event).apply

        expect(new_ticket).to include('approved_at' => 123, 'approved_by_email' => 'joe.bloggs@example.com')
      end
    end
  end
end
