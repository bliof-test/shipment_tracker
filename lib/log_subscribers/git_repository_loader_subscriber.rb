module LogSubscribers
  class GitRepositoryLoaderSubscriber < ActiveSupport::LogSubscriber
    def self.runtime=(value)
      Thread.current['git_repository_loader'] = value
    end

    def self.runtime
      Thread.current['git_repository_loader'] ||= 0
    end

    def self.reset_runtime
      rt = runtime
      self.runtime = 0
      rt
    end

    def fetch(event)
      self.class.runtime += event.duration
    end

    def clone(event)
      self.class.runtime += event.duration
    end
  end
end
