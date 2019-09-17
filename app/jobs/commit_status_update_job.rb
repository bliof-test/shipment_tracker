# frozen_string_literal: true

require 'commit_status'

class CommitStatusUpdateJob < ActiveJob::Base
  queue_as :default

  rescue_from(GithubClient::RateLimitError) do |error|
    Rails.logger.warn 'GitHub API rate limit reached. '\
      "Will retry when limit is reset at #{error.rate_limit.resets_at.strftime('%k:%M %Z')}"
    retry_job wait: error.rate_limit.resets_in
  end

  def perform(opts, method: :update)
    CommitStatus.new(full_repo_name: opts[:full_repo_name], sha: opts[:sha]).send(method)
  end
end
