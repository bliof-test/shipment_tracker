# frozen_string_literal: true

class CommitStatusUpdateJob < ActiveJob::Base
  queue_as :default

  def perform(opts)
    CommitStatus.new(full_repo_name: opts[:full_repo_name], sha: opts[:sha]).update
  end
end
