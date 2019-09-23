# frozen_string_literal: true

require 'git_clone_url'
require 'octokit'

class GithubClient
  class RateLimitError < RuntimeError
    attr_accessor :rate_limit

    def initialize(message, rate_limit)
      super(message)
      self.rate_limit = rate_limit
    end
  end

  def initialize(token)
    @token = token
  end

  def create_status(repo:, sha:, state:, description:, target_url: nil)
    return if Rails.configuration.disable_github_status_update

    begin
      client.create_status(
        repo, sha, state,
        context: 'shipment-tracker',
        description: description,
        target_url: target_url
      )
    rescue Octokit::ClientError => e
      Rails.logger.warn "Failed to set #{state} commit status for #{repo} at #{sha}: #{e.class.name} #{e.message}"

      if e.class == Octokit::TooManyRequests
        raise RateLimitError.new("Failed to set #{state} commit status for #{repo} at #{sha}", client.rate_limit)
      end
    end
  end

  def repo_accessible?(uri)
    parsed_uri = GitCloneUrl.parse(uri)
    return unless parsed_uri.host == 'github.com'

    path = parsed_uri.path
    repo_path = path.start_with?('/') ? path[1..-1] : path
    client.repository?(repo_path.chomp('.git'))
  rescue ArgumentError => error
    Rails.logger.warn(error)
    false
  end

  def last_status_for(repo:, sha:)
    response = client.combined_status(repo, sha)
  rescue Octokit::ClientError => e
    Rails.logger.warn "Failed to fetch status for #{repo} at #{sha}: #{e.class.name} #{e.message}"

    if e.class == Octokit::TooManyRequests
      raise RateLimitError.new("Failed to fetch status for #{repo} at #{sha}", client.rate_limit)
    end
  else
    response[:statuses]&.reverse&.find { |status| status[:context] == 'shipment-tracker' }
  end

  private

  def client
    @client ||= Octokit::Client.new(access_token: @token, auto_paginate: true)
  end
end
