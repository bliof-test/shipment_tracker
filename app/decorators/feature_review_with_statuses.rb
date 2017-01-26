# frozen_string_literal: true
require 'build'
require 'deploy'
require 'git_repository_location'
require 'git_repository_loader'
require 'qa_submission'
require 'ticket'
require 'uatest'

class FeatureReviewWithStatuses < SimpleDelegator
  attr_reader :builds, :deploys, :qa_submission, :release_exception, :tickets, :uatest, :time

  # rubocop:disable Metrics/LineLength, Metrics/ParameterLists
  def initialize(feature_review, builds: {}, deploys: [], qa_submission: nil, tickets: [], uatest: nil, release_exception: nil, at: nil)
    super(feature_review)
    @feature_review = feature_review
    @time = at
    @builds = builds
    @deploys = deploys
    @release_exception = release_exception
    @qa_submission = qa_submission
    @tickets = tickets
    @uatest = uatest
  end
  # rubocop:enable Metrics/LineLength, Metrics/ParameterLists

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

  def build_status
    build_results = builds.values

    return if build_results.empty?

    if build_results.all? { |b| b.success == true }
      :success
    elsif build_results.any? { |b| b.success == false }
      :failure
    end
  end

  def deploy_status
    return if deploys.empty?
    deploys.all?(&:correct) ? :success : :failure
  end

  def release_exception_status
    return unless release_exception
    release_exception.approved? ? :success : :failure
  end

  def qa_status
    return unless qa_submission
    qa_submission.accepted ? :success : :failure
  end

  def uatest_status
    return unless uatest
    uatest.success ? :success : :failure
  end

  def summary_status
    statuses = [deploy_status, qa_status, build_status]

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

    if tickets_approved?
      tickets.map(&:approved_at).max
    else
      release_exception.approved_at
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
