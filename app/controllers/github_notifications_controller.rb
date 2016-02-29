require 'git_repository_location'
require 'payloads/github'
require 'pull_request_status'

class GithubNotificationsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    if pull_request?
      process_pull_request
      head :ok
    elsif push?
      update_remote_head
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

  def push?
    github_event == 'push'
  end

  def update_remote_head
    git_repository_location = GitRepositoryLocation.find_by_full_repo_name(payload.full_repo_name)
    return unless git_repository_location
    git_repository_location.update(remote_head: payload.after_sha)
  end

  def process_pull_request
    return unless relevant_pull_request?

    status_options = { full_repo_name: payload.full_repo_name, sha: payload.head_sha }

    PullRequestStatus.new.reset(status_options)
    PullRequestUpdateJob.perform_later(status_options)
  end

  def relevant_pull_request?
    (payload.action == 'opened' || payload.action == 'synchronize') && audited_repo?
  end

  def audited_repo?
    GitRepositoryLocation.repo_exists?(payload.full_repo_name)
  end

  def payload
    @payload ||= Payloads::Github.new(params[:github_notification])
  end
end
