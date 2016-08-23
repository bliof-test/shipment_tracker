# frozen_string_literal: true
require 'build'
require 'deploy'
require 'git_repository_location'
require 'git_repository_loader'
require 'qa_submission'
require 'ticket'
require 'uatest'

class FeatureReviewWithStatuses < SimpleDelegator
  attr_reader :builds, :deploys, :qa_submission, :tickets, :uatest, :time

  # rubocop:disable Metrics/LineLength, Metrics/ParameterLists
  def initialize(feature_review, builds: {}, deploys: [], qa_submission: nil, tickets: [], uatest: nil, at: nil)
    super(feature_review)
    @feature_review = feature_review
    @time = at
    @builds = builds
    @deploys = deploys
    @qa_submission = qa_submission
    @tickets = tickets
    @uatest = uatest
  end
  # rubocop:enable Metrics/LineLength, Metrics/ParameterLists

  def github_repo_urls
    @github_repo_urls ||= GitRepositoryLocation.github_urls_for_apps(@feature_review.app_names)
  end

  def app_versions_with_commits
    app_versions.map do |app_name, version|
      [app_name, version, fetch_commits_for(app_name, version)]
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
    @authorised ||= tickets.present? && tickets.all? { |t| t.authorised?(versions) }
  end

  def authorisation_status
    return :not_approved unless tickets_approved?

    if authorised?
      :approved
    else
      :requires_reapproval
    end
  end

  def tickets_approved_at
    return unless tickets_approved?
    @approved_at ||= tickets.map(&:approved_at).max
  end

  def tickets_approved?
    @approved ||= tickets.present? && tickets.all?(&:approved?)
  end

  def approved_path
    "#{base_path}?#{query_hash.merge(time: tickets_approved_at.utc).to_query}" if authorised?
  end

  private

  def fetch_commits_for(app_name, version)
    git_repository_loader = git_repository_loader_for(app_name)
    dependent_commits(git_repository_loader, version) ||
      [commit_for_version(git_repository_loader, version)]
  end

  def dependent_commits(loader, version)
    commits = loader.get_dependent_commits(version)
    commits.presence
  end

  def commit_for_version(loader, version)
    loader.commit_for_version(version)
  end

  def git_repository_loader_for(app_name)
    GitRepositoryLoader.from_rails_config.load(app_name)
  end
end
