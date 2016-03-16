# frozen_string_literal: true
require 'git_clone_url'

class GitRepositoryLocation < ActiveRecord::Base
  before_validation on: :create do
    self.uri = uri&.strip
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
    app_names.each_with_object({}) do |app_name, github_urls|
      github_urls[app_name] = github_url_for_app(app_name)
    end
  end

  def self.find_by_full_repo_name(repo_name)
    find_by('uri LIKE ?', "%#{repo_name}%")
  end

  def self.app_remote_head_hash
    all.each_with_object({}) { |repo, repo_hash| repo_hash[repo.name] = repo.remote_head }
  end

  def self.repo_tracked?(full_repo_name)
    uris.any? { |uri| uri.include?(full_repo_name) }
  end

  def full_repo_name
    @full_repo_name ||= begin
      parsed_uri = GitCloneUrl.parse(uri)
      (parsed_uri.path.start_with?('/') ? parsed_uri.path[1..-1] : parsed_uri.path).chomp('.git')
    end
  end

  private

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
