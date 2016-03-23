# frozen_string_literal: true
require 'rails_helper'

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

  describe 'POST #create', :logged_in, :disable_repo_verification do
    before { post :create, params }

    context 'when the GitRepositoryLocation is invalid' do
      let(:params) { { repository_locations_form: { uri: 'github.com:invalid\uri' } } }

      it { is_expected.to render_template(:index) }
      it { is_expected.to set_flash.now[:error] }
    end

    context 'when the GitRepositoryLocation is valid but contains whitespace' do
      let(:params) { { repository_locations_form: { uri: ' ssh://git@github.com/some/repo.git ' } } }

      it { is_expected.to set_flash[:success] }
      it { is_expected.to redirect_to(git_repository_locations_path) }
    end

    context 'when the GitRepositoryLocation is valid' do
      let(:params) { { repository_locations_form: { uri: 'ssh://git@github.com/some/repo.git' } } }

      it { is_expected.to set_flash[:success] }
      it { is_expected.to redirect_to(git_repository_locations_path) }
    end
  end
end
