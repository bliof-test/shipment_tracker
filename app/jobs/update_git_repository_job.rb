# frozen_string_literal: true

class UpdateGitRepositoryJob < ActiveJob::Base
  queue_as :default

  def perform(args)
    repo_name = args.delete(:repo_name)
    GitRepositoryLoader.from_rails_config.load(repo_name, update_repo: true)
  end
end
