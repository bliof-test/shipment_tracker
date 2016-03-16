require 'log_subscribers/git_controller_runtime'
require 'log_subscribers/git_repository_loader_subscriber'
require 'log_subscribers/git_repository_subscriber'

LogSubscribers::GitRepositoryLoaderSubscriber.attach_to(:git_repository_loader)
LogSubscribers::GitRepositorySubscriber.attach_to(:git_repository)

ActiveSupport.on_load(:action_controller) do
  include LogSubscribers::GitControllerRuntime
end
