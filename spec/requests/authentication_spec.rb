require 'rails_helper'

RSpec.describe 'Authentication' do
  describe 'auth0' do
    context 'when not logged in' do
      it 'redirects to auth0 and sets the redirect_path' do
        get '/feature_reviews/new'

        expect(response).to redirect_to('/auth/auth0')
        follow_redirect!

        oauth_url = response['Location']
        oauth_url_query = Addressable::URI.parse(oauth_url).query_values

        expect(oauth_url_query['connection']).to eq('Username-Password-Authentication')
        expect(oauth_url_query['response_type']).to eq('code')
        expect(oauth_url_query['redirect_uri']).to end_with('/auth/auth0/callback')

        expect(session[:redirect_path]).to eq('/feature_reviews/new')
      end
    end
  end
end
