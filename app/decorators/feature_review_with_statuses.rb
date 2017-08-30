# frozen_string_literal: true
require 'build'
require 'deploy'
require 'git_repository_location'
require 'git_repository_loader'
require 'qa_submission'
require 'ticket'

class FeatureReviewWithStatuses < SimpleDelegator
  attr_reader :builds, :qa_submissions, :release_exception, :tickets, :time

  def initialize(feature_review, builds: {}, qa_submissions: nil, tickets: [], release_exception: nil, at: nil)
    super(feature_review)
    @feature_review = feature_review
    @time = at
    @builds = builds
    @release_exception = release_exception
    @qa_submissions = qa_submissions
    @tickets = tickets
  end

  def github_repo_urls
    @github_repo_urls ||= GitRepositoryLocation.github_urls_for_apps(@feature_review.app_names)
  end

  def apps_with_latest_commit
    app_versions.map do |app_name, version|
      latest_commit = fetch_commit_for(app_name, version)

      latest_commit = GitCommit.new(id: version) unless latest_commit.id

      [app_name, latest_commit]
    end
  end

  def app_url_for_version(version)
    app_name = related_app_versions.find{ |_, versions| versions.include?(version) }.first
    github_repo_urls[app_name]
  end

  def build_status
    build_results = builds.values

    return if build_results.empty?

    if build_results.all? { |b| b.success == true }
      :success
    elsif build_results.any? { |b| b.success == false }
      :failure
    end
  end

  def release_exception_status
    return unless release_exception
    release_exception.approved? ? :success : :failure
  end

  def qa_status
    return unless qa_submissions.present?
    qa_submissions.last.accepted ? :success : :failure
  end

  def summary_status
    statuses = [qa_status, build_status]

    if statuses.all? { |status| status == :success }
      :success
    elsif statuses.any? { |status| status == :failure }
      :failure
    end
  end

  def authorised?
    @authorised ||= approved_by_owner? || (tickets.present? && tickets.all? { |t| t.authorised?(versions) })
  end

  def authorisation_status
    return :approved if authorised?

    tickets_approved? ? :requires_reapproval : :not_approved
  end

  def approved_at
    return unless authorised?

    if release_exception.present?
      release_exception.approved_at
    elsif tickets_approved?
      tickets.map(&:approved_at).max
    end
  end

  def tickets_approved?
    @approved ||= tickets.present? && tickets.all?(&:approved?)
  end

  def approved_path
    "#{base_path}?#{query_hash.merge(time: approved_at.utc).to_query}" if authorised?
  end

  private

  def approved_by_owner?
    release_exception_status == :success
  end

  def fetch_commit_for(app_name, version)
    git_repository = git_repository_for(app_name)
    descendant_commits(git_repository, version)&.first ||
      commit_for_version(git_repository, version)
  end

  def descendant_commits(git_repository, version)
    git_repository.get_descendant_commits_of_branch(version).presence
  end

  def commit_for_version(git_repository, version)
    git_repository.commit_for_version(version)
  end

  def git_repository_for(app_name)
    GitRepositoryLoader.from_rails_config.load(app_name)
  end
end
