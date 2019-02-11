# frozen_string_literal: true

require 'git_repository_location'
require 'relink_ticket_job'

class HandlePushEvent
  include SolidUseCase

  steps :validate, :update_git_repository, :update_remote_head, :reset_commit_status, :relink_tickets

  def validate(payload)
    return fail :branch_deleted if payload.branch_deleted?
    return fail :annotated_tag if payload.push_annotated_tag?
    return fail :repo_not_under_audit unless GitRepositoryLocation.repo_tracked?(payload.full_repo_name)

    continue(payload)
  end

  def update_git_repository(payload)
    UpdateGitRepositoryJob.set(queue: payload.repo_name).perform_later(repo_name: payload.repo_name)
    continue(payload)
  end

  def update_remote_head(payload)
    git_repository_location = GitRepositoryLocation.find_by_full_repo_name(payload.full_repo_name)
    return fail :repo_not_found unless git_repository_location

    git_repository_location.update(remote_head: payload.head_sha)
    continue(payload)
  end

  def reset_commit_status(payload)
    return fail :protected_branch if payload.push_to_master?

    CommitStatus.new(full_repo_name: payload.full_repo_name, sha: payload.after_sha).reset
    continue(payload)
  end

  def relink_tickets(payload)
    RelinkTicketJob.perform_later(
      full_repo_name: payload.full_repo_name,
      repo_name: payload.repo_name,
      before_sha: payload.before_sha,
      after_sha: payload.after_sha,
      branch_created: payload.branch_created?,
    )

    continue(payload)
  end
end
