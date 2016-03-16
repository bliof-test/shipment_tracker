namespace :git do
  def root
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
  end

  class GitHook
    def self.all
      Dir.glob(File.join(root, 'hooks', '*')).map { |p| new(p) }
    end

    attr_reader :source_path

    def initialize(source_path)
      @source_path = source_path
    end

    def destination_path
      File.join(root, '.git', 'hooks', filename)
    end

    private

    def filename
      File.basename(source_path)
    end
  end

  desc 'Set up git hooks on the local machine'
  task :setup_hooks do
    require 'fileutils'
    GitHook.all.each do |git_hook|
      puts "Linking #{git_hook.source_path} to #{git_hook.destination_path}"
      FileUtils.ln_sf git_hook.source_path, git_hook.destination_path
    end
  end
end
