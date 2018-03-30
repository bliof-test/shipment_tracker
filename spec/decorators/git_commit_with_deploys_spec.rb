# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GitCommitWithDeploys do
  subject(:decorator) { described_class.new(git_commit, deploys: deploys) }

  let(:time) { Time.current }
  let(:git_commit) { GitCommit.new(id: 'abc', author_name: 'user', message: 'new commit', time: time) }

  let(:app_name) { 'app' }

  let(:deploys) {
    [
      Deploy.new(version: 'abc', app_name: app_name, event_created_at: time, deployed_by: 'user1'),
      Deploy.new(version: 'abd', app_name: app_name, event_created_at: time - 1.hour, deployed_by: 'user2'),
      Deploy.new(version: 'abd', app_name: app_name, event_created_at: time - 2.hours, deployed_by: 'user3'),
    ]
  }

  let(:deploys_array) do
    deploys.map do |deploy|
      {
        'app' => deploy.app_name,
        'deployed_at' => deploy.deployed_at,
        'deployed_by' => deploy.deployed_by,
        'version' => deploy.version,
      }
    end
  end

  context '#merged_by' do
    it 'returns the commit author' do
      expect(subject.merged_by).to eq(git_commit.author_name)
    end
  end

  context '#merged_at' do
    it 'returns the commit time' do
      expect(subject.time).to eq(git_commit.time)
    end
  end

  context '#app_name' do
    let(:expected_app_name) { deploys.first.app_name }

    it 'returns the app_name' do
      expect(subject.app_name).to eq(expected_app_name)
    end
  end

  describe '#github_repo_url' do
    let(:github_url) { { 'app' => 'url' } }

    before do
      allow(GitRepositoryLocation).to receive(:github_url_for_app).with(app_name).and_return(github_url)
    end

    it 'returns the repo URL for the app associated to the commit' do
      expect(decorator.github_repo_url).to eq(github_url)
    end
  end
end
