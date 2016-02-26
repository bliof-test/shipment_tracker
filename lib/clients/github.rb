require 'git_clone_url'
require 'octokit'

require 'forwardable'

class GithubClient
  extend Forwardable
  def_delegator :client, :create_status

  def initialize(token)
    @token = token
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
