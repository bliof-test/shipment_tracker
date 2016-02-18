require 'git_clone_url'

class GitRepositoryLocation < ActiveRecord::Base
  before_validation on: :create do
    self.name = extract_name(uri)
  end

  validates :uri, presence: true
  validates :name, uniqueness: true

  def self.app_names
    all.order(name: :asc).pluck(:name)
  end

  def self.uris
    all.pluck(:uri)
  end

  def self.github_url_for_app(app_name)
    repo_location = find { |r| r.name == app_name }
    return unless repo_location
    url_from_uri(repo_location.uri)
  end

  def self.github_urls_for_apps(app_names)
    github_urls = {}
    app_names.each do |app_name|
      github_urls[app_name] = github_url_for_app(app_name)
    end
    github_urls
  end

  def self.app_remote_head_hash
    all.each_with_object({}) { |repo, repo_hash| repo_hash[repo.name] = repo.remote_head }
  end

  def self.update_from_github_notification(payload)
    ssh_url = payload.fetch('repository', {}).fetch('ssh_url', nil)
    git_repository_location = find_by_github_ssh_url(ssh_url)
    return unless git_repository_location
    git_repository_location.update(remote_head: payload['after'])
  end

  private

  def self.find_by_github_ssh_url(url)
    path = Addressable::URI.parse(url).try(:path)
    find_by('uri LIKE ?', "%#{path}")
  end
  private_class_method :find_by_github_ssh_url

  def self.url_from_uri(uri)
    parsed_uri = GitCloneUrl.parse(uri)
    path = parsed_uri.path.start_with?('/') ? parsed_uri.path[1..-1] : parsed_uri.path
    "https://#{parsed_uri.host}/#{path.chomp('.git')}"
  end
  private_class_method :url_from_uri

  def extract_name(uri)
    uri.chomp('.git').split('/').last
  end
end
