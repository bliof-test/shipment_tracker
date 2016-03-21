namespace :jobs do
  def already_running?(pid_path)
    pid = File.read(pid_path)
    Process.kill(0, Integer(pid))
    true
  rescue Errno::ENOENT, Errno::ESRCH
    # no such file or pid
    false
  end

  def manage_pid(pid_path)
    fail "Pid file with running process detected, aborting (#{pid_path})" if already_running?(pid_path)
    puts "Writing pid file to #{pid_path}"
    File.open(pid_path, 'w+') do |f|
      f.write Process.pid
    end
    at_exit do
      File.delete(pid_path)
    end
  end

  def pid_path_for(name)
    require 'tmpdir'
    File.expand_path("#{name}.pid", Dir.tmpdir)
  end

  desc 'Reset and recreate event snapshots (new events received during execution are not snapshotted)'
  task recreate_snapshots: :environment do
    manage_pid pid_path_for('jobs_recreate_snapshots')

    repos = Rails.configuration.repositories.dup
    released_tickets_repo = repos.find { |repo| repo.table_name == 'released_tickets' }
    repos.delete(released_tickets_repo)

    t1 = Thread.new{
      puts "[#{Time.current}] Running recreate_snapshots for #{repos.map(&:table_name).join(', ')}"
      updater = Repositories::Updater.new(repos)

      repo_event_id_hash = Snapshots::EventCount.repo_event_id_hash # preserving the ceiling_ids before reset
      updater.reset

      updater.run(repo_event_id_hash)
      puts "[#{Time.current}] Completed recreate_snapshots for #{repos.map(&:table_name).join(', ')}"
    }

    t2 = Thread.new{
      puts "[#{Time.current}] Running recreate_snapshots for #{released_tickets_repo.table_name}"
      updater = Repositories::Updater.new([released_tickets_repo])

      repo_event_id_hash = Snapshots::EventCount.repo_event_id_hash # preserving the ceiling_ids before reset
      updater.reset

      updater.run(repo_event_id_hash)
      puts "[#{Time.current}] Completed recreate_snapshots for #{released_tickets_repo.table_name}"
    }

    t1.join
    t2.join
  end

  desc 'Continuously updates event cache'
  task update_events_loop: :environment do
    Signal.trap('TERM') do
      warn 'Terminating rake task jobs:update_events_loop...'
      @shutdown = true
    end

    loop do
      break if @shutdown
      start_time = Time.current
      puts "[#{start_time}] Running update_events"
      lowest_event_id = Snapshots::EventCount.all.min_by(&:event_id).try(:event_id).to_i

      Repositories::Updater.from_rails_config.run

      end_time = Time.current
      num_events = Events::BaseEvent.where('id > ?', lowest_event_id).count
      puts "[#{end_time}] Cached #{num_events} events in #{end_time - start_time} seconds"
      break if @shutdown
      sleep 5
    end
  end

  desc 'Continuously updates the local git repositories'
  task update_git_loop: :environment do
    manage_pid pid_path_for('update_git_loop')

    Signal.trap('TERM') do
      warn 'Terminating rake task jobs:update_git_loop...'
      @shutdown = true
    end

    loader = GitRepositoryLoader.from_rails_config
    repos_hash_changed = GitRepositoryLocation.app_remote_head_hash
    repos_hash_before = repos_hash_changed.dup

    loop do
      start_time = Time.current
      puts "[#{start_time}] Updating #{repos_hash_changed.size} git repositories"

      repos_hash_changed.keys.in_groups(4).map { |group|
        Thread.new do # Limited to 4 threads to avoid running out of memory.
          group.compact.each do |app_name|
            break if @shutdown
            loader.load(app_name, update_repo: true)
          end
        end
      }.each(&:join)

      repos_hash_after = GitRepositoryLocation.app_remote_head_hash
      repos_hash_changed = repos_hash_after.select { |name, remote_head|
        remote_head != repos_hash_before[name]
      }
      repos_hash_before = repos_hash_after.dup

      end_time = Time.current
      puts "[#{end_time}] Updated git repositories in #{end_time - start_time} seconds"
      sleep 5
    end
  end
end
