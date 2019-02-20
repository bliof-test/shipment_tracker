# frozen_string_literal: true

class UpdateGitRepositoryJob < ActiveJob::Base
  queue_as :update_git_repositories

  def perform(args)
    GitRepositoryLoader.from_rails_config.load(args[:repo_name], update_repo: true)

    RelinkTicketJob.perform_later(**args)
  end
end
