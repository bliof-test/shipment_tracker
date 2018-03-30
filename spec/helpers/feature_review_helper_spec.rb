# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeatureReviewsHelper do
  describe '#jira_link' do
    let(:jira_key) { 'JIRA-123' }
    let(:expected_link) { link_to(jira_key, 'https://jira.test/browse/JIRA-123', target: '_blank') }
    it 'returns a link to the relevant jira ticket' do
      stub_const('ShipmentTracker::JIRA_FQDN', 'https://jira.test')
      expect(helper.jira_link(jira_key)).to eq(expected_link)
    end
  end

  describe '#owner_of_any_repo?' do
    let!(:repo_owner) { FactoryBot.create(:repo_admin, email: 'test@example.com') }
    let!(:git_repos) { [FactoryBot.create(:git_repository_location, name: 'app1')] }
    let(:feature_review) { double(:feature_review, app_names: %w[app1]) }

    before do
      allow_any_instance_of(Repositories::RepoOwnershipRepository)
        .to receive(:owners_of).and_return([repo_owner])
    end

    context 'the current user is an owner of a repo' do
      let(:user) { User.new(email: 'test@example.com') }

      it 'returns true' do
        expect(helper.owner_of_any_repo?(user, feature_review)).to be true
      end
    end

    context 'the current user is not an owner of a repo' do
      let(:user) { User.new(email: 'test2@example.com') }

      it 'returns false' do
        expect(helper.owner_of_any_repo?(user, feature_review)).to be false
      end
    end
  end
end
