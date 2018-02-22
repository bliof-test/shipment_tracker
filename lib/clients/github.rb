# frozen_string_literal: true
require 'git_clone_url'
require 'octokit'

class GithubClient
  def initialize(token)
    @token = token
  end

  def create_status(repo:, sha:, state:, description:, target_url: nil)
    client.create_status(
      repo, sha, state,
      context: 'shipment-tracker',
      description: description,
      target_url: target_url
    )
  rescue Octokit::NotFound
    Rails.logger.warn "Failed to set #{state} commit status for #{repo} at #{sha}"
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
    client.combined_status(repo, sha)[:statuses].reverse.find do |status|
      status[:context] == 'shipment-tracker'
    end
  rescue Octokit::Error
    Rails.logger.warn "Failed to fetch status for #{repo} at #{sha}"
    nil
  end

  private

  def client
    @client ||= Octokit::Client.new(access_token: @token, auto_paginate: true)
  end
end
