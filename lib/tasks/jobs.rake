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

  desc 'Update event cache'
  task update_events: :environment do
    manage_pid pid_path_for('jobs_update_events')

    puts "[#{Time.current}] Running update_events"
    Repositories::Updater.from_rails_config.run
    puts "[#{Time.current}] Completed update_events"
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

  desc 'Continuously updates the git cache'
  task update_git_cache_loop: :environment do
    Signal.trap('TERM') do
      warn 'Terminating rake task jobs:update_git_cache_loop...'
      @shutdown = true
    end

    loader = GitRepositoryLoader.from_rails_config
    repos_hash_changed = GitRepositoryLocation.app_remote_head_hash

    loop do
      start_time = Time.current
      puts "[#{start_time}] Running update git cache for all apps"

      repos_hash_changed.each_key { |name|
        Thread.new do
          break if @shutdown
          loader.load_and_update(name)
        end
      }.each(&:join)

      repos_hash_after = GitRepositoryLocation.app_remote_head_hash
      repos_hash_changed = repos_hash_after.delete_if { |name, remote_head|
        remote_head == repos_hash_changed[name]
      }

      end_time = Time.current
      puts "[#{end_time}] Updated git in #{end_time - start_time} seconds"
      sleep 5
    end
  end
end
