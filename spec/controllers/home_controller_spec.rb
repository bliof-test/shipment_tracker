# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HomeController do
  context 'when logged out' do
    it { is_expected.to require_authentication_on(:get, :index) }
  end

  describe 'GET #index', :logged_in do
    let(:tickets) { [double] }
    let(:repo) { double }

    before do
      allow(Repositories::ReleasedTicketRepository).to receive(:new).and_return(repo)
      allow(repo).to receive(:tickets_for_query).and_return(tickets)
    end

    it 'displays no tickets' do
      get :index, preview: 'true'

      expect(response).to have_http_status(:success)
      expect(assigns(:tickets)).to eq([])
    end

    it 'searches tickets for the given query' do
      expect(repo).to receive(:tickets_for_query).with(query_text: 'dog', versions: []).and_return(tickets)

      get :index, preview: 'true', q: 'dog'

      expect(response).to have_http_status(:success)
      expect(assigns(:tickets)).to eq(tickets)
    end

    context "when params include 'to' and 'from'" do
      it 'passes end of day for to and beginning of day for from to the query' do
        expect(repo).to receive(:tickets_for_query).with(
          query_text: '',
          versions: [],
          from_date: DateTime.parse('2016-03-20').beginning_of_day,
          to_date: DateTime.parse('2016-03-30').end_of_day,
        ).and_return(tickets)

        get :index, preview: 'true', q: '', to: '2016-03-30', from: '2016-03-20'

        expect(response).to have_http_status(:success)
        expect(assigns(:tickets)).to eq(tickets)
      end
    end
  end
end
