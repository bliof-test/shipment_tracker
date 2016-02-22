require 'git_clone_url'
require 'octokit'
require 'singleton'

class OctokitClient
  include Singleton

  def initialize(token: ENV['GITHUB_REPO_STATUS_ACCESS_TOKEN'])
    @client = Octokit::Client.new(access_token: token)
  end

  def repo_accessible?(uri)
    parsed_uri = GitCloneUrl.parse(uri)
    return unless parsed_uri.host == 'github.com'

    path = parsed_uri.path
    repo_path = path.start_with?('/') ? path[1..-1] : path
    @client.repository?(repo_path.chomp('.git'))
  end

  def create_status(*args)
    @client.create_status(*args)
  end
end
