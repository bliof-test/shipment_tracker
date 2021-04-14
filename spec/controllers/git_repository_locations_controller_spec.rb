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
    before { post :create, params: params }

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

  describe 'GET #edit', :logged_in do
    it 'can be rendered' do
      repo = FactoryBot.create(:git_repository_location)

      get :edit, params: { id: repo }

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH #update', :logged_in do
    context 'with correct parameters' do
      let(:repo) { FactoryBot.create(:git_repository_location) }
      let(:params) {
        {
          id: repo,
          forms_edit_git_repository_location_form: { repo_owners: 'test@example.com' },
        }
      }

      it 'sets the owner of the repo' do
        patch :update, params: params

        expect(repo.owners.first.email).to eq('test@example.com')
      end

      it 'redirects to edit and sets successful flash' do
        patch :update, params: params

        expect(response).to redirect_to(action: :index)
        expect(flash[:success]).to be_present
      end
    end

    context 'with incorrect parameters' do
      let(:repo) { FactoryBot.create(:git_repository_location) }
      let(:params) {
        {
          id: repo,
          forms_edit_git_repository_location_form: { repo_owners: 'testexample.com' },
        }
      }

      it 'does not change the owner of the repo' do
        expect { patch :update, params: params }.not_to change { repo.reload }
      end

      it 'renders edit and does not set successful flash' do
        patch :update, params: params

        expect(response).to render_template(:edit)
        expect(flash[:success]).not_to be_present
      end
    end
  end
end
