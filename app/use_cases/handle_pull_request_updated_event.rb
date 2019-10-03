# frozen_string_literal: true

require 'relink_ticket_job'
require 'handle_pull_request_event_base'

class HandlePullRequestUpdatedEvent < HandlePullRequestEventBase
  steps :validate, :update_remote_head, :reset_commit_status, :relink_tickets

  def reset_commit_status(payload)
    CommitStatusResetJob.perform_later(
      full_repo_name: payload.full_repo_name,
      sha: payload.after_sha,
    )

    continue(payload)
  end

  def relink_tickets(payload)
    RelinkTicketJob.perform_later(
      full_repo_name: payload.full_repo_name,
      before_sha: payload.before_sha,
      after_sha: payload.after_sha,
    )

    continue(payload)
  end
end
