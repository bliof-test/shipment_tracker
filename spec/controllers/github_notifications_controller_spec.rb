# frozen_string_literal: true
require 'rails_helper'

RSpec.describe GithubNotificationsController do
  describe 'POST #create', :logged_in do
    context 'when event is a push notification' do
      before do
        request.env['HTTP_X_GITHUB_EVENT'] = 'push'
      end

      it 'runs the HandlePushEvent use case' do
        expect(HandlePushEvent).to receive(:run).with(anything)

        post :create, github_notification: {}
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
