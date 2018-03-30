# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Queries::ReleasesQuery do
  subject(:releases_query) {
    Queries::ReleasesQuery.new(
      per_page: 50,
      region: 'gb',
      git_repo: git_repository,
      app_name: app_name,
    )
  }

  let(:deploy_repository) { instance_double(Repositories::DeployRepository) }
  let(:git_repository) { instance_double(GitRepository) }

  let(:app_name) { 'foo' }
  let(:time) { Time.current }
  let(:formatted_time) { time.to_formatted_s(:long_ordinal) }

  let(:commits) {
    [
      GitCommit.new(id: 'abc', message: 'new commit on master', time: time - 1.hour, parent_ids: ['def']),
      GitCommit.new(id: 'def', message: 'merge commit', time: time - 2.hours, parent_ids: %w[ghi xyz]),
      GitCommit.new(id: 'ghi', message: 'first commit on master branch', time: time - 3.hours),
    ]
  }

  let(:versions) { commits.map(&:id) }
  let(:associated_versions) { %w[abc def xyz ghi] }
  let(:deploy_time) { time - 1.hour }

  let(:deploys) {
    [
      Deploy.new(version: 'def', app_name: app_name, deployed_at: deploy_time, deployed_by: 'auser'),
    ]
  }

  let(:decorated_feature_reviews_query) {
    instance_double(Queries::DecoratedFeatureReviewsQuery)
  }

  let(:feature_reviews) {
    [
      double(versions: ['abc'], authorised?: false),
      double(versions: ['def'], authorised?: false),
      double(versions: ['ghi'], authorised?: true),
    ]
  }

  before do
    allow(Repositories::DeployRepository).to receive(:new).and_return(deploy_repository)
    allow(git_repository).to receive(:recent_commits_on_main_branch).with(50).and_return(commits)
    allow(deploy_repository).to receive(:deploys_for_versions)
      .with(versions, environment: 'production', region: 'gb')
      .and_return(deploys)
    allow(Queries::DecoratedFeatureReviewsQuery).to receive(:new).and_return(decorated_feature_reviews_query)

    commits.each do |commit|
      allow(decorated_feature_reviews_query)
        .to receive(:get)
        .with(commit)
        .and_return(feature_reviews.select { |fr| fr.versions.include? commit.id })
    end
  end

  describe '#versions' do
    subject(:query_versions) { releases_query.versions }
    it 'returns all versions' do
      expect(query_versions).to eq(%w[abc def ghi])
    end
  end

  describe '#pending_releases' do
    subject(:pending_releases) { releases_query.pending_releases }
    it 'returns list of releases not yet deployed to production' do
      expect(pending_releases.map(&:version)).to eq(['abc'])
      expect(pending_releases.map(&:subject)).to eq(['new commit on master'])
      expect(pending_releases.map(&:production_deploy_time)).to eq([nil])
      expect(pending_releases.map(&:deployed_by)).to eq([nil])
      expect(pending_releases.map(&:authorised?)).to eq([false])
      expect(pending_releases.map(&:feature_reviews).flatten)
        .to eq(feature_reviews.select { |fr| fr.versions == ['abc'] })
    end
  end

  describe '#deployed_releases' do
    let(:authorised_feature_review) {
      feature_reviews.find { |fr| fr.versions == ['def'] }
    }

    let(:new_feature_review_for_unauthorised_deploy) {
      feature_reviews.find { |fr| fr.versions == ['ghi'] }
    }

    subject(:deployed_releases) { releases_query.deployed_releases }
    it 'returns list of releases deployed to production in region "gb"' do
      expect(deployed_releases.map(&:version)).to eq(%w[def ghi])
      expect(deployed_releases.map(&:subject)).to eq(['merge commit', 'first commit on master branch'])
      expect(deployed_releases.map(&:production_deploy_time)).to eq([deploy_time, nil])
      expect(deployed_releases.map(&:deployed_by)).to eq(['auser', nil])

      expect(deployed_releases.map(&:feature_reviews)).to eq(
        [[authorised_feature_review], [new_feature_review_for_unauthorised_deploy]],
      )
    end
  end
end
