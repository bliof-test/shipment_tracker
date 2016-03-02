require 'rails_helper'
require 'handle_pull_request_event'

RSpec.describe HandlePullRequestEvent do
  context 'when the pull request is not for an audited repo' do
    it 'does not set the pull request status' do
      allow(GitRepositoryLocation).to receive(:repo_exists?).and_return(false)

      expect(PullRequestStatus).to_not receive(:new)
      expect(PullRequestUpdateJob).to_not receive(:perform_later)

      payload = instance_double(Payloads::Github, action: 'opened', full_repo_name: 'owner/repo')

      result = HandlePullRequestEvent.run(payload)
      expect(result).to be_failure
    end
  end

  context 'when the pull request activity is not relevant' do
    it 'does not set the pull request status' do
      allow(GitRepositoryLocation).to receive(:repo_exists?).and_return(true)

      expect(PullRequestStatus).to_not receive(:new)
      expect(PullRequestUpdateJob).to_not receive(:perform_later)

      payload = instance_double(Payloads::Github, action: 'reopened', full_repo_name: 'owner/repo')

      HandlePullRequestEvent.run(payload)
    end
  end

  context 'when the pull request receives a new commit' do
    it 'resets then sets the pull request status' do
      allow(GitRepositoryLocation).to receive(:repo_exists?).and_return(true)
      pull_request_status = instance_double(PullRequestStatus)
      allow(PullRequestStatus).to receive(:new).and_return(pull_request_status)

      expect(pull_request_status).to receive(:reset).with(
        full_repo_name: 'owner/repo',
        sha: 'abc123',
      ).ordered

      expect(pull_request_status).to receive(:update).with(
        full_repo_name: 'owner/repo',
        sha: 'abc123',
      ).ordered

      payload = instance_double(
        Payloads::Github,
        action: 'synchronize',
        full_repo_name: 'owner/repo',
        head_sha: 'abc123',
      )

      HandlePullRequestEvent.run(payload)
    end
  end

  context 'when the pull request is newly opened' do
    it 'resets and sets the pull request status' do
      allow(GitRepositoryLocation).to receive(:repo_exists?).and_return(true)
      pull_request_status = instance_double(PullRequestStatus)
      allow(PullRequestStatus).to receive(:new).and_return(pull_request_status)

      expect(pull_request_status).to receive(:reset).with(
        full_repo_name: 'owner/repo',
        sha: 'abc123',
      ).ordered

      expect(pull_request_status).to receive(:update).with(
        full_repo_name: 'owner/repo',
        sha: 'abc123',
      ).ordered

      payload = instance_double(
        Payloads::Github,
        action: 'opened',
        full_repo_name: 'owner/repo',
        head_sha: 'abc123',
      )

      HandlePullRequestEvent.run(payload)
    end
  end
end
