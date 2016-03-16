require 'rails_helper'
require 'repositories/released_ticket_repository'
require 'snapshots/released_ticket'
require 'ticket'

RSpec.describe Repositories::ReleasedTicketRepository do
  subject(:ticket_repo) { Repositories::ReleasedTicketRepository.new(store) }
  let(:store) { double }
  describe '#tickets_for_query' do
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
    let(:event) { build(:jira_event, key: 'JIRA-123', summary: 'My old ticket', description: 'Some words') }
    let(:store) { Snapshots::ReleasedTicket }
    let(:event_hash) {
      {
        'key' => event.key,
        'summary' => event.summary,
        'description' => event.description,
      }
    }

    context 'when ticket exists' do
      let!(:existing_ticket_key) do
        Snapshots::ReleasedTicket.create('key' => 'JIRA-1', 'summary' => 'My old ticket').key
      end

      let(:event) { build(:jira_event, key: existing_ticket_key, summary: 'My new title') }

      it 'updates existing ticket' do
        expect(Snapshots::ReleasedTicket.count).to eq 1
        ticket_repo.apply(event)
        expect(Snapshots::ReleasedTicket.count).to eq 1
        attributes = Snapshots::ReleasedTicket.last.attributes.select { |k, _v| event_hash.keys.include?(k) }
        expect(attributes).to eq(event_hash)
      end
    end

    context 'when ticket is new' do
      it 'creates new record' do
        expect(Snapshots::ReleasedTicket.count).to eq 0
        ticket_repo.apply(event)
        expect(Snapshots::ReleasedTicket.count).to eq 1
        attributes = Snapshots::ReleasedTicket.last.attributes.select { |k, _v| event_hash.keys.include?(k) }
        expect(attributes).to eq(event_hash)
      end
    end

    context 'when event is not JiraEvent' do
      let(:event) { build(:deploy_event) }

      it 'does not create a record' do
        ticket_repo.apply(event)
        expect(Snapshots::ReleasedTicket.count).to eq 0
      end
    end
  end
end
