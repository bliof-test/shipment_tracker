# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Events::Handlers::TicketHandler do
  describe '#apply' do
    let(:time) { Time.current.change(usec: 0) }
    let(:ticket_defaults) { { paths: [path], versions: %w(foo), version_timestamps: { 'foo' => nil } } }
    let(:url) { feature_review_url(app: 'foo') }
    let(:path) { feature_review_path(app: 'foo') }
    let(:email) { 'test@example.com' }
    let(:email2) { 'test2@example.com' }

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
        created_ticket_event = build(:jira_event, :approved, created_at: time + 1.hour)

        new_ticket = described_class.new(ticket, created_ticket_event).apply

        expect(new_ticket).to include('approved_at' => time + 1.hour)
      end

      it "updates authored_by with event's assignee email if the previous ticket does not have authored_by" do
        ticket = {}
        created_ticket_event = build(:jira_event, :approved, created_at: time + 1.hour, assignee_email: email)

        new_ticket = described_class.new(ticket, created_ticket_event).apply

        expect(new_ticket).to include('authored_by' => email)
      end

      it "updates authored_by with previous ticket's authored_by if the previous ticket has authored_by" do
        ticket = { 'authored_by' => email2 }
        created_ticket_event = build(:jira_event, :approved, created_at: time + 1.hour, assignee_email: email)

        new_ticket = described_class.new(ticket, created_ticket_event).apply

        expect(new_ticket).to include('authored_by' => email2)
      end
    end

    context 'when the event is development' do
      it "updates authored_by with event's user email" do
        ticket = {}
        created_ticket_event = build(:jira_event, :started, created_at: time + 1.hour)

        new_ticket = described_class.new(ticket, created_ticket_event).apply

        expect(new_ticket).to include('authored_by' => 'joe.bloggs@example.com')
      end
    end

    context 'when ticket is present and event is PAST approval' do
      it 'uses approved_at from previous event' do
        ticket = { 'approved_at' => 123 }
        created_ticket_event = build(:jira_event, :deployed, created_at: time + 1.hour)

        new_ticket = described_class.new(ticket, created_ticket_event).apply

        expect(new_ticket).to include('approved_at' => 123)
      end
    end
  end
end
