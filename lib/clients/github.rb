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
  end

  def repo_accessible?(uri)
    parsed_uri = GitCloneUrl.parse(uri)
    return unless parsed_uri.host == 'github.com'

    path = parsed_uri.path
    repo_path = path.start_with?('/') ? path[1..-1] : path
    client.repository?(repo_path.chomp('.git'))
  end

  private

  def client
    @client ||= Octokit::Client.new(access_token: @token, auto_paginate: true)
  end
end
