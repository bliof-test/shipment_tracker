require 'git_repository_location'
require 'relink_ticket_job'

class HandlePushEvent
  include SolidUseCase

  steps :update_remote_head, :reset_commit_status, :relink_tickets

  def update_remote_head(payload)
    # Only enables the functionality for our test repo
    # TODO: remove when production ready
    return fail :other_repos unless payload.full_repo_name == 'FundingCircle/hello_world_rails'
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
      head_sha: payload.head_sha
    )

    continue(payload)
  end
end
