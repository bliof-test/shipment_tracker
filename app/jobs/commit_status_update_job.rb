# frozen_string_literal: true

class CommitStatusUpdateJob < ActiveJob::Base
  queue_as :default

  def perform(opts, method: :update)
    CommitStatus.new(full_repo_name: opts[:full_repo_name], sha: opts[:sha]).send(method)
  end
end
