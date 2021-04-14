# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleasesController do
  context 'when logged out' do
    it { is_expected.to require_authentication_on(:get, :index) }
    it { is_expected.to require_authentication_on(:get, :show, id: 'frontend') }
  end

  describe 'GET #index', :logged_in do
    let(:app_names) { %w[frontend backend] }

    before do
      allow(GitRepositoryLocation).to receive(:app_names).and_return(app_names)
    end

    it 'displays the list of apps' do
      get :index

      expect(response).to have_http_status(:success)
      expect(assigns(:app_names)).to eq(app_names)
    end
  end

  describe 'GET #show', :logged_in do
    let(:repository) { instance_double(GitRepository) }
    let(:repository_loader) { instance_double(GitRepositoryLoader) }
    let(:events) { double(:events) }
    let(:app_name) { 'frontend' }
    let(:github_url) { 'https://github.com/user/repo' }
    let(:pending_releases) { double(:pending_releases) }
    let(:deployed_releases) { double(:deployed_releases) }
    let(:releases_query) {
      instance_double(
        Queries::ReleasesQuery,
        pending_releases: pending_releases,
        deployed_releases: deployed_releases,
      )
    }

    before do
      allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(repository_loader)
      allow(repository_loader).to receive(:load).with(app_name).and_return(repository)
      allow(GitRepositoryLocation).to receive(:github_url_for_app).with(app_name).and_return(github_url)
      allow(Queries::ReleasesQuery).to receive(:new).with(
        per_page: 50,
        region: anything,
        git_repo: repository,
        app_name: app_name,
      ).and_return(releases_query)
      allow(Events::BaseEvent).to receive(:in_order_of_creation).and_return(events)
    end

    it 'shows the list of commits for an app' do
      get :show, params: { id: app_name, region: 'gb' }

      expect(response).to have_http_status(:success)
      expect(assigns(:app_name)).to eq(app_name)
      expect(assigns(:pending_releases)).to eq(pending_releases)
      expect(assigns(:deployed_releases)).to eq(deployed_releases)
      expect(assigns(:github_repo_url)).to eq(github_url)
    end

    context 'when app id does not exist' do
      before do
        allow(repository_loader).to receive(:load).and_raise(GitRepositoryLoader::NotFound)
      end

      it 'responds with a 404' do
        get :show, params: { id: 'hokus-pokus', region: 'gp' }

        expect(response).to be_not_found
      end
    end

    context 'when no region is passed in and no cookie set' do
      it 'redirects to region "gb"' do
        get :show, params: { id: app_name }
        expect(response).to have_http_status(:redirect)
        expect(response.redirect_url).to eq('http://test.host/releases/frontend?region=gb')
      end

      it 'sets cookie to region "gb"' do
        get :show, params: { id: app_name }
        expect(response.cookies['deploy_region']).to eq('gb')
      end
    end

    context 'when no region is passed and deploy region cookie is set' do
      let(:region) { 'us' }

      it 'redirects to releases with same region as set in cookie' do
        request.cookies['deploy_region'] = region
        get :show, params: { id: app_name }
        expect(response).to have_http_status(:redirect)
        expect(response.redirect_url).to eq("http://test.host/releases/frontend?region=#{region}")
        expect(cookies['deploy_region']).to eq(region)
      end
    end

    context 'when "de" region is passed and deploy region cookie is set to "nl"' do
      let(:cookie_region) { 'nl' }
      let(:params_region) { 'de' }

      it 'navigates to releases with same region as set in parameters and updates cookie value' do
        cookies['deploy_region'] = cookie_region
        get :show, params: { id: app_name, region: params_region }
        expect(cookies['deploy_region']).to eq(params_region)
      end
    end
  end
end
