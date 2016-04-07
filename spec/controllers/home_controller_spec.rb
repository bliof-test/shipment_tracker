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

    it 'searches for tickets deployed today when search params are empty' do
      get :index

      expect(response).to redirect_to(root_path(from: Time.zone.today, to: Time.zone.today))
    end

    it 'searches tickets for the given query and extracts SHAs' do
      expect(repo).to receive(:tickets_for_query).with(
        query_text: 'some text',
        versions: ['cf5a10f6ddff6fb5199bb86893bf77e48a82cbce'],
      )

      get :index, q: ' some text cf5a10f6ddff6fb5199bb86893bf77e48a82cbce'

      expect(response).to have_http_status(:success)
    end

    it 'flashes a warning and still performs the search when a date is unparsable' do
      get :index, from: 'not a date'

      expect(flash[:warning]).to eq('invalid date')
      expect(response).to be_ok
    end
  end
end
