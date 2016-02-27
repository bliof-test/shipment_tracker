require 'rails_helper'

RSpec.describe GithubNotificationsController do
  describe 'POST #create', :logged_in do
    context 'when event is a pull request' do
      before do
        request.env['HTTP_X_GITHUB_EVENT'] = 'pull_request'
      end

      context 'when the pull request is newly opened' do
        let(:sha) { '12345' }
        let(:repo_url) { 'https://github.com/FundingCircle/hello_world_rails' }

        it 'sets the pull request status' do
          allow(GitRepositoryLocation).to receive(:repo_exists?).and_return(true)
          pull_request_status = instance_double(PullRequestStatus)
          allow(PullRequestStatus).to receive(:new).and_return(pull_request_status)

          expect(pull_request_status).to receive(:reset).with(
            repo_url: repo_url,
            sha: sha,
          ).ordered

          expect(pull_request_status).to receive(:update).with(
            repo_url: repo_url,
            sha: sha,
          ).ordered

          post :create, github_notification: pr_payload(action: 'opened', repo_url: repo_url, sha: sha)
        end
      end

      context 'when the pull request receives a new commit' do
        let(:sha) { '12345' }
        let(:repo_url) { 'https://github.com/FundingCircle/hello_world_rails' }

        it 'sets the pull request status' do
          allow(GitRepositoryLocation).to receive(:repo_exists?).and_return(true)
          pull_request_status = instance_double(PullRequestStatus)
          allow(PullRequestStatus).to receive(:new).and_return(pull_request_status)

          expect(pull_request_status).to receive(:reset).with(
            repo_url: repo_url,
            sha: sha,
          ).ordered

          expect(pull_request_status).to receive(:update).with(
            repo_url: repo_url,
            sha: sha,
          ).ordered

          post :create, github_notification: pr_payload(action: 'synchronize', repo_url: repo_url, sha: sha)
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

      let(:payload) { {} }

      it 'updates the corresponding repository location' do
        expect(GitRepositoryLocation).to receive(:update_from_github_notification).with(payload)

        post :create, payload
      end
    end

    context 'when event is not recognized' do
      it 'responds with a 202 Accepted' do
        post :create

        expect(response).to have_http_status(:accepted)
      end
    end
  end

  def pr_payload(action:, repo_url:, sha:)
    {
      'action' => action,
      'pull_request' => {
        'head' => {
          'sha' => sha,
        },
        'base' => {
          'repo' => {
            'html_url' => repo_url,
          },
        },
      },
    }
  end
end
