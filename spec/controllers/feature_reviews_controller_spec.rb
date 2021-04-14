# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'links the ticket with correct Jira id' do |ticket_id:|
  it 'links the ticket' do
    expect(LinkTicket).to receive(:run).with(
      jira_key: ticket_id,
      feature_review_path: feature_review_path(apps_with_versions),
      root_url: 'http://test.host/',
    )

    link_ticket
  end
end

RSpec.describe FeatureReviewsController do
  context 'when logged out' do
    it { is_expected.to require_authentication_on(:get, :new) }
    it { is_expected.to require_authentication_on(:get, :show) }
    it { is_expected.to require_authentication_on(:post, :create) }
    it { is_expected.to require_authentication_on(:post, :link_ticket) }
  end

  before do
    repository1 = instance_double(GitRepository, get_dependent_commits: [double(id: 'abc')])
    repository2 = instance_double(GitRepository, get_dependent_commits: [double(id: 'def')])

    allow_any_instance_of(GitRepositoryLoader).to receive(:load).with('frontend').and_return(repository1)
    allow_any_instance_of(GitRepositoryLoader).to receive(:load).with('backend').and_return(repository2)
  end

  describe 'GET #new', :logged_in do
    let(:feature_review_form) { instance_double(Forms::FeatureReviewForm) }

    before do
      allow(GitRepositoryLocation).to receive(:app_names).and_return(%w[frontend backend])
      allow(Forms::FeatureReviewForm).to receive(:new).with(hash_including(apps: nil)).and_return(feature_review_form)
    end

    it 'renders the form' do
      get :new
      is_expected.to render_template('new')
      expect(assigns(:feature_review_form)).to eq(feature_review_form)
      expect(assigns(:app_names)).to eq(%w[frontend backend])
    end
  end

  describe 'POST #create', :logged_in do
    let(:git_repository_loader) { instance_double(GitRepositoryLoader) }
    let(:feature_review_form) { instance_double(Forms::FeatureReviewForm) }
    let(:repo) { instance_double(GitRepository) }

    before do
      allow(Forms::FeatureReviewForm).to receive(:new).with(
        apps: { frontend: 'abc' },
        git_repository_loader: git_repository_loader,
      ).and_return(feature_review_form)
      allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(git_repository_loader)
    end

    context 'when the params are invalid' do
      it 'renders the new page' do
        allow(Forms::FeatureReviewForm).to receive(:new).and_return(feature_review_form)
        allow(feature_review_form).to receive(:valid?).and_return(false)

        post :create

        is_expected.to render_template('new')
        expect(assigns(:feature_review_form)).to eql(feature_review_form)
      end
    end

    context 'when the feature review form is invalid' do
      before do
        allow(feature_review_form).to receive(:valid?).and_return(false)
        allow(GitRepositoryLocation).to receive(:app_names).and_return(%w[frontend backend])
      end

      it 'renders the new page' do
        post :create, params: { forms_feature_review_form: { apps: { frontend: 'abc' } } }

        is_expected.to render_template('new')
        expect(assigns(:feature_review_form)).to eql(feature_review_form)
        expect(assigns(:app_names)).to eql(%w[frontend backend])
      end
    end

    context 'when the feature review form is valid' do
      before do
        allow(feature_review_form).to receive(:valid?).and_return(true)
        allow(feature_review_form).to receive(:path).and_return('/the/url')
      end

      it 'redirects to #show' do
        post :create, params: { forms_feature_review_form: { apps: { frontend: 'abc' } } }

        is_expected.to redirect_to('/the/url')
      end
    end
  end

  describe 'GET #show', :logged_in do
    let(:apps_with_versions) { { 'frontend' => 'abc', 'backend' => 'def' } }
    let(:feature_review) {
      instance_double(FeatureReview)
    }
    let(:feature_review_query) { instance_double(Queries::FeatureReviewQuery) }
    let(:feature_review_factory) { instance_double(Factories::FeatureReviewFactory) }
    let(:feature_review_with_statuses) { instance_double(FeatureReviewWithStatuses) }
    let(:host) { 'www.example.com' }

    before do
      request.host = host

      allow(Queries::FeatureReviewQuery).to receive(:new).and_return(feature_review_query)
      allow(feature_review_query).to receive(:feature_review_with_statuses)
        .and_return(feature_review_with_statuses)

      allow(Factories::FeatureReviewFactory).to receive(:new).and_return(feature_review_factory)
      allow(feature_review_factory)
        .to receive(:create_from_url_string)
        .with("http://#{host}#{whitelisted_path}")
        .and_return(feature_review)
    end

    context 'when time is NOT specified' do
      let(:whitelisted_path) { feature_review_path(apps_with_versions) }

      it 'sets up the correct query parameters' do
        expect(Queries::FeatureReviewQuery).to receive(:new)
          .with(feature_review, at: nil)
          .and_return(feature_review_query)

        get :show, params: { apps: apps_with_versions }

        expect(assigns(:feature_review_with_statuses)).to eq(feature_review_with_statuses)
      end
    end

    context 'when time is specified' do
      let(:whitelisted_path) { feature_review_path(apps_with_versions, time) }
      let(:time) { Time.parse('2015-09-09 12:00:00 UTC') }
      let(:precise_time) { time.change(usec: 999_999.999) }

      it 'sets up the correct query parameters' do
        expect(Queries::FeatureReviewQuery).to receive(:new)
          .with(feature_review, at: precise_time)
          .and_return(feature_review_query)

        get :show, params: { apps: apps_with_versions, time: time }

        expect(assigns(:feature_review_with_statuses)).to eq(feature_review_with_statuses)
      end
    end
  end

  describe 'POST #link_ticket', :logged_in do
    let(:ticket_id) { 'JIRA-123' }
    let(:apps_with_versions) { { 'frontend' => 'abc', 'backend' => 'def' } }
    let(:message) { 'Some message' }

    subject(:link_ticket) {
      post :link_ticket, params: { return_to: feature_review_path(apps_with_versions), jira_key: ticket_id }
    }

    before do
      allow(LinkTicket).to receive(:run).and_return(Success(message))
    end

    it 'links the ticket' do
      expect(LinkTicket).to receive(:run).with(
        jira_key: ticket_id,
        feature_review_path: feature_review_path(apps_with_versions),
        root_url: 'http://test.host/',
      )

      link_ticket
    end

    it 'shows a flash success message' do
      link_ticket
      expect(flash[:success]).to eq(message)
    end

    it 'redirects to the return path' do
      link_ticket
      expect(response).to redirect_to(feature_review_path(apps_with_versions))
    end

    context 'linking fails' do
      let(:error) { double(:error, message: message) }

      before do
        allow(LinkTicket).to receive(:run).and_return(Failure(error))
      end

      it 'shows flash error message' do
        link_ticket
        expect(flash[:error]).to eq(message)
      end

      it 'redirects to the return path' do
        link_ticket
        expect(response).to redirect_to(feature_review_path(apps_with_versions))
      end
    end

    context 'ticket id has trailing space' do
      let(:ticket_id) { 'JIRA-123 ' }

      it_behaves_like 'links the ticket with correct Jira id', ticket_id: 'JIRA-123'
    end

    context 'ticket id has leading space' do
      let(:ticket_id) { ' JIRA-123' }

      it_behaves_like 'links the ticket with correct Jira id', ticket_id: 'JIRA-123'
    end

    context 'ticket id has lowercase letters' do
      let(:ticket_id) { ' jira-123' }

      it_behaves_like 'links the ticket with correct Jira id', ticket_id: 'JIRA-123'
    end
  end
end
