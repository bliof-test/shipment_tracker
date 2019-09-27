# frozen_string_literal: true

require 'git_repository_location'
require 'relink_ticket_job'

class HandlePullRequestUpdatedEvent
  include SolidUseCase
  include PullRequestEventValidatable

  steps :validate, :update_remote_head, :reset_commit_status, :relink_tickets

  def update_remote_head(payload)
    git_repository_location = GitRepositoryLocation.find_by_full_repo_name(payload.full_repo_name)
    return fail :repo_not_found unless git_repository_location

    git_repository_location.update(remote_head: payload.after_sha)
    continue(payload)
  end

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
