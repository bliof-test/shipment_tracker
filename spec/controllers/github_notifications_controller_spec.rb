# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GithubNotificationsController do
  describe 'POST #create', :logged_in do
    context 'when event is a push notification' do
      before do
        request.env['HTTP_X_GITHUB_EVENT'] = 'push'
      end

      it 'responds with a 202 Accepted' do
        post :create

        expect(response).to have_http_status(:accepted)
      end
    end

    context 'when event is a pull request notification' do
      before do
        request.env['HTTP_X_GITHUB_EVENT'] = 'pull_request'
      end

      context 'when event is a pull request opened' do
        it 'runs the correct use case and responds with a 200 OK' do
          expect(HandlePullRequestCreatedEvent).to receive(:run).with(anything)

          post :create, github_notification: { 'action' => 'opened' }

          expect(response).to have_http_status(:ok)
        end
      end

      context 'when event is a pull request updated' do
        it 'runs the correct use case and responds with a 200 OK' do
          expect(HandlePullRequestUpdatedEvent).to receive(:run).with(anything)

          post :create, github_notification: { 'action' => 'synchronize' }

          expect(response).to have_http_status(:ok)
        end
      end

      context 'when event is a pull request merged' do
        it 'runs the correct use case and responds with a 200 OK' do
          expect(HandlePullRequestMergedEvent).to receive(:run).with(anything)

          post :create, github_notification: { 'action' => 'closed', 'pull_request' => { 'merged' => true } }

          expect(response).to have_http_status(:ok)
        end
      end

      context 'when event is an other pull request event' do
        it 'responds with a 202 Accepted' do
          post :create, github_notification: { 'action' => 'edited' }

          expect(response).to have_http_status(:accepted)
        end
      end
    end

    context 'when event is not recognized' do
      it 'responds with a 202 Accepted' do
        post :create

        expect(response).to have_http_status(:accepted)
      end
    end
  end
end
