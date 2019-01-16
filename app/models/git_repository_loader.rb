# frozen_string_literal: true

require 'git_clone_url'
require 'git_repository'

require 'active_support/notifications'
require 'rugged'

class GitRepositoryLoader
  class NotFound < RuntimeError; end
  class BadLocation < RuntimeError; end

  RETRY_LIMIT = 10

  def self.from_rails_config
    @repo_loader ||= new(
      ssh_private_key: Rails.configuration.ssh_private_key,
      ssh_public_key: Rails.configuration.ssh_public_key,
      ssh_user: Rails.configuration.ssh_user,
      cache_dir: Rails.configuration.git_repository_cache_dir,
    )
  end

  def initialize(ssh_private_key: nil, ssh_public_key: nil, ssh_user: nil, cache_dir: Dir.tmpdir)
    @ssh_private_key = ssh_private_key
    @ssh_public_key = ssh_public_key
    @ssh_user = ssh_user
    @cache_dir = cache_dir
  end

  def load(repository_name, update_repo: Rails.configuration.allow_git_fetch_on_request)
    FileUtils.makedirs(cache_dir)
    Rails.logger.info "loading changes for #{repository_name}..."
    git_repository_location = find_repo_location(repository_name)

    repository = load_rugged_repository(update: update_repo, location: git_repository_location)
    Rails.logger.info "loaded changes for #{repository_name}"

    GitRepository.new(repository)
  end

  private

  attr_reader :cache_dir, :ssh_user, :ssh_private_key, :ssh_public_key

  def find_repo_location(repository_name)
    git_repository_location = GitRepositoryLocation.find_by_name(repository_name)
    unless git_repository_location
      fail GitRepositoryLoader::NotFound,
        "Cannot find GitRepositoryLocation record for #{repository_name.inspect}"
    end
    git_repository_location
  end

  def updated_rugged_repository(git_repository_location, options)
    dir = repository_dir_name(git_repository_location)
    Rugged::Repository.bare(dir, options).tap do |repository|
      fetch_repository(git_repository_location, repository, options)
    end
  rescue Rugged::OSError, Rugged::RepositoryError, Rugged::InvalidError, Rugged::ReferenceError => error
    Rails.logger.warn "Exception while updating repository: #{error.message}"
    cloned_repository(git_repository_location, options)
  end

  def fetch_repository(git_repository_location, repository, options)
    retries ||= 0
    instrument('fetch') do
      repository.fetch('origin', options) unless up_to_date?(git_repository_location, repository)
    end
  rescue Rugged::OSError => error
    raise unless fetch_in_progress?(error)
    name = git_repository_location.name
    if retries < RETRY_LIMIT
      retries += 1
      Rails.logger.warn "Another fetch is in progress for #{name}, retrying in 1 second (#{retries}/#{RETRY_LIMIT})"
      sleep 1
      retry
    end
    Rails.logger.warn "Reached retry limit for fetch of #{name}, giving up"
  end

  def cloned_repository(git_repository_location, options)
    dir = repository_dir_name(git_repository_location)
    Rails.logger.info "Wiping directory #{dir} and re-cloning repository to the same location..."
    FileUtils.rmtree(dir)
    instrument('clone') do
      Rugged::Repository.clone_at(git_repository_location.uri, dir, options.merge(bare: true))
    end
  end

  def rugged_repository(git_repository_location)
    dir = repository_dir_name(git_repository_location)
    Rugged::Repository.bare(dir)
  rescue Rugged::OSError, Rugged::RepositoryError => error
    Rails.logger.warn "Cannot access repository, will try to re-clone/re-fetch. Exception: #{error.message}"
    load_rugged_repository(update: true, location: git_repository_location)
  end

  def repository_dir_name(git_repository_location)
    File.join(cache_dir, "#{git_repository_location.id}-#{git_repository_location.name}")
  end

  def options_for(uri, &block)
    parsed_uri = GitCloneUrl.parse(uri)
    if ['ssh', 'git', nil].include?(parsed_uri.scheme) && parsed_uri.user == 'git'
      options_for_ssh(&block)
    else
      yield({})
    end
  end

  def up_to_date?(git_repository_location, rugged_repository)
    git_repository_location.remote_head == rugged_repository.head.target_id
  end

  def create_temporary_file(key)
    file = Tempfile.open('key')
    begin
      file.write(key.strip + "\n")
    ensure
      file.close
    end

    file
  end

  def options_for_ssh
    fail 'ssh_user not set' unless ssh_user
    fail 'ssh_public_key not set' unless ssh_public_key
    fail 'ssh_private_key not set' unless ssh_private_key

    ssh_public_key_file = create_temporary_file(ssh_public_key)
    ssh_private_key_file = create_temporary_file(ssh_private_key)

    yield credentials: Rugged::Credentials::SshKey.new(
      username: ssh_user,
      publickey: ssh_public_key_file.path,
      privatekey: ssh_private_key_file.path,
    )
  ensure
    ssh_public_key_file&.unlink
    ssh_private_key_file&.unlink
  end

  def instrument(name, &block)
    ActiveSupport::Notifications.instrument(
      "#{name}.git_repository_loader",
      &block
    )
  end

  def load_rugged_repository(update:, location:)
    if update
      options_for(location.uri) { |options|
        updated_rugged_repository(location, options)
      }
    else
      rugged_repository(location)
    end
  end

  def fetch_in_progress?(error)
    return false unless error.class == Rugged::OSError

    !!(error.message =~ /failed to create locked file/i && error.message =~ /File exists/i)
  end
end
