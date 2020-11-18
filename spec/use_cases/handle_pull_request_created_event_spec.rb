# frozen_string_literal: true

require 'rails_helper'
require 'handle_pull_request_created_event'
require 'payloads/github_pull_request'

RSpec.describe HandlePullRequestCreatedEvent do
  subject(:handle) { described_class.run(payload) }

  let(:payload_data) {
    {
      'pull_request' => {
        'head' => {
          'sha' => 'def1234',
          'ref' => branch_name,
        },
        'base' => {
          'ref' => base_branch,
          'repo' => {
            'full_name' => 'owner/repo_name',
            'name' => 'repo_name',
          },
        },
        'title' => 'A Cool Title',
      },
      'before' => 'abc1234',
      'after' => 'def1234',
    }
  }
  let(:payload) { Payloads::GithubPullRequest.new(payload_data) }
  let(:branch_name) { 'branch-name' }
  let(:base_branch) { 'master' }

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
        expect(handle).to fail_with(:repo_not_under_audit)
      end
    end

    context 'when base branch is not "master"' do
      let(:base_branch) { 'other-base-branch' }

      it 'fails' do
        expect(handle).to fail_with(:base_not_master)
      end
    end
  end

  it 'resets the GitHub commit status' do
    expect {
      handle
    }.to have_enqueued_job(CommitStatusNotFoundJob).with(
      full_repo_name: payload.full_repo_name,
      sha: payload.head_sha
    )
  end

  it 'attempts to automatically link a Jira ticket' do
    expect {
      handle
    }.to have_enqueued_job(AutoLinkTicketJob).with(
      repo_name: payload.repo_name,
      head_sha: payload.head_sha,
      branch_name: payload.branch_name,
      title: payload.title,
    )
  end
end
