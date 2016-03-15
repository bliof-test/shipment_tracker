# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'ReleasesControllerFormats', type: :request do
  describe 'GET /releases/<app_name>', :logged_in do
    before do
      allow(Queries::ReleasesQuery).to receive(:new).and_return(double.as_null_object)
      allow_any_instance_of(GitRepositoryLoader).to receive(:load)
      allow(GitRepositoryLocation).to receive(:github_url_for_app)
    end

    context 'when app name contains a valid non-html format' do
      it 'assigns the app name correctly' do
        get '/releases/example.js?region=gb'

        expect(response).to have_http_status(:success)
        expect(assigns(:app_name)).to eq('example.js')
      end
    end

    context 'when app name does not contain a format' do
      it 'assigns the app name correctly' do
        get '/releases/example?region=gb'

        expect(response).to have_http_status(:success)
        expect(assigns(:app_name)).to eq('example')
      end
    end
  end
end
