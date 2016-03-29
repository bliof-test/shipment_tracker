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

    it 'displays the list of apps' do
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
  end
end
