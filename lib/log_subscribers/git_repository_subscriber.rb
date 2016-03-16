module LogSubscribers
  class GitRepositorySubscriber < ActiveSupport::LogSubscriber
    def self.runtime=(value)
      Thread.current['git_repository'] = value
    end

    def self.runtime
      Thread.current['git_repository'] ||= 0
    end

    def self.reset_runtime
      rt = runtime
      self.runtime = 0
      rt
    end

    def commits_between(event)
      self.class.runtime += event.duration
    end
  end
end
