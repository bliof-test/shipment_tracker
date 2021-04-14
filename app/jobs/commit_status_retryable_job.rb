# frozen_string_literal: true

class CommitStatusRetryableJob < ApplicationJob
  rescue_from(GithubClient::RateLimitError) do |error|
    Rails.logger.warn 'GitHub API rate limit reached. '\
      "Will retry when limit is reset at #{error.rate_limit.resets_at.strftime('%k:%M %Z')}"
    retry_job wait: error.rate_limit.resets_in
  end
end
