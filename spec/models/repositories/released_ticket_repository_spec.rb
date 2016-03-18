require 'rails_helper'
require 'repositories/released_ticket_repository'
require 'snapshots/released_ticket'
require 'ticket'

RSpec.describe Repositories::ReleasedTicketRepository do
  subject(:ticket_repo) { Repositories::ReleasedTicketRepository.new(store) }

  describe '#tickets_for_query' do
    let(:store) { double }
    let(:query) { double }
    let(:ticket) { double(Snapshots::Ticket, attributes: {}) }

    before do
      allow(store).to receive(:search_for).and_return([ticket])
    end

    it 'delegates search to store' do
      ticket_repo.tickets_for_query(query)
      expect(store).to have_received(:search_for).with(query)
    end

    it 'returns Ticket objects' do
      tickets = ticket_repo.tickets_for_query(query)
      expect(tickets.first).to be_a_kind_of(Ticket)
    end

    context 'when no tickets found' do
      before do
        allow(store).to receive(:search_for).and_return([])
      end

      it 'returns empty array' do
        tickets = ticket_repo.tickets_for_query(query)
        expect(tickets).to be_empty
      end
    end
  end

  describe '#apply' do
    let(:store) { Snapshots::ReleasedTicket }
    let(:event_attrs) {
      {
        'key' => 'JIRA-123',
        'summary' => 'some summary',
        'description' => 'some description',
      }
    }

    context 'when ticket exists' do
      it 'updates existing ticket' do
        Snapshots::ReleasedTicket.create(key: 'JIRA-1', summary: 'foo', description: 'bar', versions: ['abc'])
        event = build(
          :jira_event,
          key: 'JIRA-1',
          summary: 'new title',
          description: 'new description',
          comment_body: feature_review_url(app1: 'def', app2: 'ghi'),
        )
        expect { ticket_repo.apply(event) }.to_not change { Snapshots::ReleasedTicket.count }

        expected_attributes = {
          'key' => 'JIRA-1',
          'summary' => 'new title',
          'description' => 'new description',
          'versions' => %w(abc def ghi),
        }
        expect(Snapshots::ReleasedTicket.last.attributes).to include(expected_attributes)
      end
    end

    context 'when ticket is new' do
      context 'when ticket has Feature Reviews' do
        it 'snapshots' do
          event = build(:jira_event, event_attrs.merge(comment_body: feature_review_url(app: 'abc')))
          expect { ticket_repo.apply(event) }.to change { Snapshots::ReleasedTicket.count }.by(1)

          expected_attrs = event_attrs.merge('versions' => ['abc'])
          expect(Snapshots::ReleasedTicket.last.attributes).to include(expected_attrs)
        end
      end

      context 'when ticket has no Feature Reviews' do
        it 'does not snapshot' do
          event = build(:jira_event, event_attrs)
          expect { ticket_repo.apply(event) }.to_not change { Snapshots::ReleasedTicket.count }
        end
      end
    end

    it 'does not apply the event when it is irrelevant' do
      event = build(:uat_event)
      expect { ticket_repo.apply(event) }.not_to change { Snapshots::ReleasedTicket.count }
    end
  end
end
