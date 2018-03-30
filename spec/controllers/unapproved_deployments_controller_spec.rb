# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnapprovedDeploymentsController do
  context 'when logged out' do
    it { is_expected.to require_authentication_on(:get, :show, id: 'frontend') }
  end

  describe 'GET #show', :logged_in do
    let(:app_name) { 'frontend' }
    let(:release_exceptions) { double(:release_exceptions) }
    let(:unapproved_deploys) { double(:unapproved_deploys) }

    before do
      allow_any_instance_of(Repositories::DeployRepository)
        .to receive(:unapproved_production_deploys_for)
        .with(any_args)
        .and_return(unapproved_deploys)

      allow_any_instance_of(Repositories::ReleaseExceptionRepository)
        .to receive(:release_exception_for_application)
        .with(any_args)
        .and_return(release_exceptions)
    end

    it 'shows the list of commits for an app' do
      get :show, id: app_name, region: 'gb'

      expect(response).to have_http_status(:success)
      expect(assigns(:app_name)).to eq(app_name)
      expect(assigns(:release_exceptions)).to eq(release_exceptions)
      expect(assigns(:unapproved_deploys)).to eq(unapproved_deploys)
    end
  end
end
