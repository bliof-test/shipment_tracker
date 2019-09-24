# frozen_string_literal: true

require 'commit_status'

class CommitStatusNotFoundJob < CommitStatusRetryableJob
  queue_as :default

  def perform(opts)
    CommitStatus.new(full_repo_name: opts[:full_repo_name], sha: opts[:sha]).not_found
  end
end
