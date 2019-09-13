# frozen_string_literal: true

require 'payloads/github_pull_request'

class GithubNotificationsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    if pull_request?
      if pull_request_payload.updated?
        HandlePullRequestUpdatedEvent.run(pull_request_payload)
      elsif pull_request_payload.created?
        HandlePullRequestCreatedEvent.run(pull_request_payload)
      end
      head :ok
    else
      head :accepted
    end
  end

  private

  def unauthenticated_strategy
    self.status = 403
    self.response_body = 'Forbidden'
  end

  def github_event
    request.env['HTTP_X_GITHUB_EVENT']
  end

  def pull_request?
    github_event == 'pull_request'
  end

  def pull_request_payload
    @pull_request_payload ||= Payloads::GithubPullRequest.new(params[:github_notification])
  end
end
