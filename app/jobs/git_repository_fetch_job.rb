class GitRepositoryFetchJob < ActiveJob::Base
  queue_as :default

  def perform(attrs)
    loader = GitRepositoryLoader.from_rails_config

    loader.load_and_update(attrs.fetch(:name))
  end
end
