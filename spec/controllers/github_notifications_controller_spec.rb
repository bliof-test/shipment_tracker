require 'rails_helper'

RSpec.describe GithubNotificationsController do
  describe 'POST #create', :logged_in do
    context 'when event is a pull request notification' do
      before do
        request.env['HTTP_X_GITHUB_EVENT'] = 'pull_request'
      end

      context 'when the pull request is newly opened' do
        it 'reset and sets the pull request status' do
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

          post :create, github_notification:
            pr_payload(action: 'opened', full_repo_name: 'owner/repo', sha: 'abc123')
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

          post :create, github_notification:
            pr_payload(action: 'synchronize', full_repo_name: 'owner/repo', sha: 'abc123')
        end
      end

      context 'when the pull request activity is not relevant' do
        it 'does not set the pull request status' do
          expect(PullRequestStatus).to_not receive(:new)
          expect(PullRequestUpdateJob).to_not receive(:perform_later)

          post :create, github_notification: { action: 'reopened' }
        end
      end

      context 'when the pull request is not for an audited repo' do
        before do
          allow(GitRepositoryLocation).to receive(:repo_exists?).and_return(false)
        end

        it 'does not set the pull request status' do
          expect(PullRequestStatus).to_not receive(:new)
          expect(PullRequestUpdateJob).to_not receive(:perform_later)

          post :create, github_notification: { action: 'opened' }
        end
      end
    end

    context 'when event is a push notification' do
      before do
        request.env['HTTP_X_GITHUB_EVENT'] = 'push'
      end

      it 'runs the handle_push_event use case' do
        expect(HandlePushEvent).to receive(:run).with(anything)

        post :create, github_notification: { after: 'abc123', repository: { full_name: 'owner/repo' } }
      end
    end

    context 'when event is not recognized' do
      it 'responds with a 202 Accepted' do
        post :create

        expect(response).to have_http_status(:accepted)
      end
    end
  end

  def pr_payload(action:, full_repo_name:, sha:)
    {
      'action' => action,
      'repository' => {
        'full_name' => full_repo_name,
      },
      'pull_request' => {
        'head' => {
          'sha' => sha,
        },
      },
    }
  end
end
