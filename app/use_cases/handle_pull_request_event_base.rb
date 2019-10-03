# frozen_string_literal: true

require 'solid_use_case'

require 'git_repository_location'
require 'pull_request_event_validatable'

class HandlePullRequestEventBase
  include SolidUseCase
  include PullRequestEventValidatable

  def update_remote_head(payload)
    git_repository_location = GitRepositoryLocation.find_by_full_repo_name(payload.full_repo_name)
    return fail :repo_not_found unless git_repository_location

    git_repository_location.update(remote_head: payload.after_sha)
    continue(payload)
  end
end
