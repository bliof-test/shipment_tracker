require 'rails_helper'

include Shoulda::Matchers::ActionController # FIXME: https://github.com/thoughtbot/shoulda-matchers/issues/903

RSpec.describe GitRepositoryLocationsController do
  context 'when logged out' do
    let(:repo_location) {
      {
        'name' => 'shipment_tracker',
        'uri' => 'https://github.com/FundingCircle/shipment_tracker.git',
      }
    }

    it { is_expected.to require_authentication_on(:get, :index) }
    it { is_expected.to require_authentication_on(:post, :create, git_repository_location: repo_location) }
  end

  describe 'GET #index', :logged_in do
    subject { get :index }
    it { is_expected.to have_http_status(:success) }
  end

  describe 'POST #create', :logged_in do
    before { post :create, params }

    context 'when the GitRepositoryLocation is invalid' do
      let(:params) { { git_repository_location: { name: 'app', uri: 'github.com:invalid\uri' } } }

      it { is_expected.to render_template(:index) }
      it { is_expected.to set_flash.now[:error] }
    end

    context 'when the GitRepositoryLocation is valid' do
      let(:params) { { git_repository_location: { name: 'app', uri: 'ssh://git@github.com/some/repo.git' } } }

      it { is_expected.to redirect_to(git_repository_locations_path) }
    end
  end
end
