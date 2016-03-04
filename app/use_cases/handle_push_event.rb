require 'git_repository_location'
require 'relink_ticket_job'

class HandlePushEvent
  include SolidUseCase

  steps :validate, :update_remote_head, :reset_commit_status, :relink_tickets

  def validate(payload)
    return fail :repo_not_under_audit unless GitRepositoryLocation.repo_tracked?(payload.full_repo_name)
    continue(payload)
  end

  def update_remote_head(payload)
    git_repository_location = GitRepositoryLocation.find_by_full_repo_name(payload.full_repo_name)
    return fail :repo_not_found unless git_repository_location
    git_repository_location.update(remote_head: payload.after_sha)
    continue(payload)
  end

  def reset_commit_status(payload)
    status_options = { full_repo_name: payload.full_repo_name, sha: payload.head_sha }

    CommitStatus.new.reset(status_options)
    continue(payload)
  end

  def relink_tickets(payload)
    RelinkTicketJob.perform_later(
      full_repo_name: payload.full_repo_name,
      before_sha: payload.before_sha,
      after_sha: payload.after_sha,
      head_sha: payload.head_sha,
    )

    continue(payload)
  end
end
