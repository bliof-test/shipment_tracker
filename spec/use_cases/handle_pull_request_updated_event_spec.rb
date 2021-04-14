# frozen_string_literal: true

require 'rails_helper'
require 'handle_pull_request_updated_event'
require 'payloads/github_pull_request'

RSpec.describe HandlePullRequestUpdatedEvent do
  let(:payload_data) {
    {
      'pull_request' => {
        'head' => { 'sha' => 'def1234', 'ref' => branch_name },
        'base' => { 'ref' => base_branch, 'repo' => { 'full_name' => repository } },
      },
      'before' => 'abc1234',
      'after' => 'def1234',
    }
  }
  let(:payload) { Payloads::GithubPullRequest.new(payload_data) }
  let(:branch_name) { 'branch-name' }
  let(:base_branch) { 'master' }
  let(:repository) { 'owner/repo_1' }

  before do
    allow_any_instance_of(CommitStatus).to receive(:reset)
    allow(GitRepositoryLocation).to receive(:repo_tracked?).and_return(true)
    ActiveJob::Base.queue_adapter = :test
  end

  describe 'validation' do
    context 'when repo is not audited' do
      before do
        allow(GitRepositoryLocation).to receive(:repo_tracked?).and_return(false)
      end

      it 'fails' do
        result = described_class.run(payload)
        expect(result).to fail_with(:repo_not_under_audit)
      end
    end

    context 'when base branch is not "master"' do
      let(:base_branch) { 'other-base-branch' }

      it 'fails' do
        result = described_class.run(payload)
        expect(result).to fail_with(:base_not_master)
      end
    end
  end

  describe 'updating remote head' do
    context 'when repo not found' do
      before do
        allow(GitRepositoryLocation).to receive(:find_by_full_repo_name).and_return(nil)
      end

      it 'fails' do
        result = described_class.run(payload)
        expect(result).to fail_with(:repo_not_found)
      end
    end

    context 'repo exists' do
      let(:git_repository_location) { instance_double(GitRepositoryLocation) }
      let(:git_repository_loader) { instance_double(GitRepositoryLoader) }
      let(:git_repository) { instance_double(GitRepository) }

      before do
        allow_any_instance_of(CommitStatus).to receive(:not_found)

        allow(GitRepositoryLocation).to receive(:find_by_full_repo_name).and_return(git_repository_location)

        allow(GitRepositoryLoader).to receive(:from_rails_config) { git_repository_loader }
        allow(git_repository_loader).to receive(:load) { git_repository }
        allow(git_repository).to receive(:commit_on_master?) { false }
      end

      it 'updates the corresponding repository location' do
        expect(git_repository_location).to receive(:update).with(remote_head: 'def1234')
        described_class.run(payload)
      end
    end
  end

  describe 'resetting commit status' do
    let(:git_repository_location) { instance_double(GitRepositoryLocation, update: nil) }

    before do
      allow(GitRepositoryLocation).to receive(:find_by_full_repo_name).and_return(git_repository_location)
    end

    it 'resets the GitHub commit status' do
      expect {
        described_class.run(payload)
      }.to have_enqueued_job(CommitStatusResetJob).with(
        full_repo_name: repository,
        sha: payload_data['after']
      )

      described_class.run(payload)
    end
  end

  describe 'relinking tickets' do
    let(:git_repository_location) { instance_double(GitRepositoryLocation, update: nil) }

    before do
      allow(GitRepositoryLocation).to receive(:find_by_full_repo_name).and_return(git_repository_location)
    end

    it 'relinks the ticket' do
      expect {
        described_class.run(payload)
      }.to have_enqueued_job(RelinkTicketJob).with(
        full_repo_name: repository,
        before_sha: payload_data['before'],
        after_sha: payload_data['after'],
      )

      described_class.run(payload)
    end
  end
end
