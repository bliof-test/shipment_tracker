# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('config/application', __dir__)

Rails.application.load_tasks

if Rails.env.test?
  begin
    require 'rspec/core/rake_task'
    task default: %i[spec cucumber rubocop]

    Rake::Task['spec'].clear
    desc 'Run all specs in spec directory (excluding plugin specs)'
    RSpec::Core::RakeTask.new(spec: 'spec:prepare') do |task|
      task.exclude_pattern = 'spec/performance/**/*.rb'
    end

    Rake::Task['spec:performance'].clear
    desc 'Run all the performance specs'
    RSpec::Core::RakeTask.new('spec:performance') do |task|
      task.pattern = 'spec/performance/**/*.rb'
    end
  rescue LoadError
    # Custom RSpec tasks disabled as RSpec is not available
    desc 'RSpec is not available, please install `rspec-core`'
    task :spec
  end
end
