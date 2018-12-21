# frozen_string_literal: true

require 'honeybadger'

namespace :jobs do
  desc 'Reset and recreate event snapshots (new events received during execution are not snapshotted)'
  task recreate_snapshots: :environment do
    Rails.logger.info 'Running recreate_snapshots'

    Repositories::Updater.from_rails_config.recreate

    Rails.logger.info 'Completed recreate_snapshots'
  end

  desc 'Continuously updates event cache'
  task update_events_loop: :environment do
    Signal.trap('TERM') do
      Rails.logger.warn 'Terminating rake task jobs:update_events_loop...'
      @shutdown = true
    end

    Rails.logger.tagged('update_events_loop') do
      until @shutdown
        start_time = Time.current
        Rails.logger.info 'Running update_events'

        from_event_id = Snapshots::EventCount.global_event_pointer

        Repositories::Updater.from_rails_config.run

        last_event_id = Snapshots::EventCount.global_event_pointer

        num_events = Events::BaseEvent.where('id > ?', from_event_id).where('id <= ?', last_event_id).count

        end_time = Time.current
        Rails.logger.info "Applied #{num_events} events in #{end_time - start_time} seconds"

        sleep 5 unless @shutdown
      end
    end
  end

  desc 'Continuously updates the local git repositories'
  task update_git_loop: :environment do
    Signal.trap('TERM') do
      Rails.logger.warn 'Terminating rake task jobs:update_git_loop...'
      @shutdown = true
    end

    loader = GitRepositoryLoader.from_rails_config
    repos_hash_changed = GitRepositoryLocation.app_remote_head_hash
    repos_hash_before = repos_hash_changed.dup

    until @shutdown
      start_time = Time.current
      Rails.logger.info "Updating #{repos_hash_changed.size} git repositories"

      repos_hash_changed.keys.in_groups(4).map { |group|
        Thread.new do # Limited to 4 threads to avoid running out of memory.
          group.compact.each do |app_name|
            break if @shutdown

            begin
              loader.load(app_name, update_repo: true)
            rescue StandardError => error
              Honeybadger.notify(
                error,
                context: {
                  app_name: app_name,
                  remote_head: repos_hash_changed[app_name],
                },
              )
            end
          end
        end
      }.each(&:join)

      repos_hash_after = GitRepositoryLocation.app_remote_head_hash
      repos_hash_changed = repos_hash_after.reject { |name, remote_head|
        remote_head == repos_hash_before[name]
      }
      repos_hash_before = repos_hash_after.dup

      end_time = Time.current
      Rails.logger.info "Updated git repositories in #{end_time - start_time} seconds"
      sleep 5 unless @shutdown
    end
  end
end
