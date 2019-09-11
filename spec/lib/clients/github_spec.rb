# frozen_string_literal: true

require 'rails_helper'
require 'clients/github'

RSpec.describe GithubClient do
  subject(:github) { GithubClient.new('token') }

  describe '#create_status' do
    it 'creates a commit status' do
      expect_any_instance_of(Octokit::Client).to receive(:create_status).with(
        'owner/repo', 'abc123', 'success', context: 'shipment-tracker', description: 'foo', target_url: 'url'
      )

      github.create_status(
        repo: 'owner/repo', sha: 'abc123', state: 'success', description: 'foo', target_url: 'url',
      )
    end

    it 'does not raise if status failed to be created' do
      expect_any_instance_of(Octokit::Client).to receive(:create_status).and_raise(Octokit::NotFound)

      expect {
        github.create_status(repo: 'owner/repo', sha: 'abc123', state: 'success', description: 'foo')
      }.to_not raise_error
    end

    context 'when disabled' do
      before do
        allow(Rails.configuration).to receive(:disable_github_status_update).and_return(true)
      end

      it 'does not update the status' do
        expect_any_instance_of(Octokit::Client).not_to receive(:create_status)
        github.create_status(repo: 'owner/repo', sha: 'abc123', state: 'success', description: 'foo')
      end
    end
  end

  describe '#repo_accessible?' do
    context 'when repo is on GitHub' do
      it 'checks that the repo is accessible' do
        %w[git@github.com:owner/repo.git
           git://github.com/owner/repo.git
           ssh://github.com/owner/repo.git
           http://github.com/owner/repo].each do |uri|
          expect_any_instance_of(Octokit::Client).to receive(:repository?).with('owner/repo')
          github.repo_accessible?(uri)
        end
      end
    end

    context 'when repo is not on GitHub' do
      it 'does not check GitHub and returns nil' do
        expect_any_instance_of(Octokit::Client).to_not receive(:repository?)
        expect(github.repo_accessible?('git@bitbucket.com:owner/repo.git')).to be_nil
      end
    end

    context 'when the format is not owner/repo' do
      it 'returns false' do
        expect(github.repo_accessible?('https://github.com/foo')).to be false
      end
    end
  end

  describe '#last_status_for' do
    let(:status_pending) {
      {
        'created_at': '2018-02-22T01:19:13Z',
        'updated_at': '2018-02-22T01:19:13Z',
        'state': 'pending',
        'target_url': 'https://shipment-tracker.example.com/feature_reviews?apps%5Brepo%5D=abc123',
        'description': 'Re-approval required for Feature Review',
        'id': 1,
        'url': 'https://api.github.com/repos/owner/repo/statuses/abc123',
        'context': 'shipment-tracker',
      }
    }

    let(:status_success) {
      {
        'created_at': '2018-02-22T01:20:00Z',
        'updated_at': '2018-02-22T01:20:00Z',
        'state': 'success',
        'target_url': 'https://shipment-tracker.example.com/feature_reviews?apps%5Brepo%5D=abc123',
        'description': 'Approved Feature Review found',
        'id': 1,
        'url': 'https://api.github.com/repos/owner/repo/statuses/abc123',
        'context': 'shipment-tracker',
      }
    }

    let(:combined_status) {
      {
        statuses: [status_pending, status_success],
      }
    }

    it 'fetches the last status' do
      expect_any_instance_of(Octokit::Client).to receive(:combined_status).with(
        'owner/repo', 'abc123'
      ).and_return(combined_status)

      expect(github.last_status_for(repo: 'owner/repo', sha: 'abc123')).to eq(status_success)
    end

    it 'does not raise if status fetch failed' do
      expect_any_instance_of(Octokit::Client).to receive(:combined_status).and_raise(Octokit::Error)

      expect { github.last_status_for(repo: 'owner/repo', sha: 'abc123') }.to_not raise_error
    end

    context 'when the response has no statuses' do
      let(:combined_status) { {} }

      it 'returns nil' do
        expect_any_instance_of(Octokit::Client).to receive(:combined_status).with(
          'owner/repo', 'abc123'
        ).and_return(combined_status)

        expect(github.last_status_for(repo: 'owner/repo', sha: 'abc123')).to be_nil
      end
    end
  end
end
