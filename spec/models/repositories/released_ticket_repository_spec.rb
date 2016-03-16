require 'spec_helper'
require 'repositories/released_ticket_repository'
require 'ticket'

RSpec.describe Repositories::ReleasedTicketRepository do
  describe '#tickets_for_query' do
    subject(:ticket_repo) { Repositories::ReleasedTicketRepository.new(store) }
    let(:store) {double}
    let(:query) {double}
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
end
