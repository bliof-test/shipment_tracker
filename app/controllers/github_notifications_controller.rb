# frozen_string_literal: true
require 'payloads/github'

class GithubNotificationsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    if push?
      HandlePushEvent.run(payload)
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

  def push?
    github_event == 'push'
  end

  def payload
    @payload ||= Payloads::Github.new(params[:github_notification])
  end
end
