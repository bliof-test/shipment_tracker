# frozen_string_literal: true
require 'active_support/json'
require 'octokit'
require 'clients/github'
require 'factories/feature_review_factory'
require 'feature_review_with_statuses'
require 'repositories/deploy_repository'
require 'repositories/ticket_repository'

class CommitStatus
  attr_reader :full_repo_name, :sha

  def initialize(full_repo_name:, sha:)
    @routes = Rails.application.routes.url_helpers
    @full_repo_name = full_repo_name
    @sha = sha
  end

  def update
    status, description = feature_reviews_status.values_at(:status, :description)

    if !last_status || (last_status.state != status && last_status.description != description)
      post_status({ status: status, description: description }, target_url)
    end
  end

  def reset
    post_status(searching_status)
  end

  def error
    post_status(error_status)
  end

  def not_found
    post_status(not_found_status, target_url)
  end

  def last_status
    @last_status ||= github.last_status_for(repo: full_repo_name, sha: sha)
  end

  private

  def commit
    GitCommit.new(id: sha)
  end

  def post_status(notification, target_url = nil)
    github.create_status(
      repo: full_repo_name,
      sha: sha,
      state: notification[:status],
      description: notification[:description],
      target_url: target_url,
    )
  end

  attr_reader :routes

  def decorated_feature_reviews
    @decorated_feature_review ||= decorated_feature_reviews_query.get(commit)
  end

  def decorated_feature_reviews_query
    Queries::DecoratedFeatureReviewsQuery.new(short_repo_name, [commit])
  end

  def target_url
    if decorated_feature_reviews.length == 1
      url_to_feature_review(decorated_feature_reviews.first.path)
    else
      url_to_search_feature_reviews
    end
  end

  def short_repo_name
    full_repo_name.split('/').last
  end

  def url_to_feature_review(feature_review_path)
    routes.root_url.chomp('/') + feature_review_path
  end

  def url_to_search_feature_reviews
    routes.root_url(q: sha)
  end

  def feature_reviews_status
    if only_new_feature_review?
      not_found_status
    elsif decorated_feature_reviews.any?(&:authorised?)
      approved_status
    elsif decorated_feature_reviews.any?(&:tickets_approved?)
      reapproval_status
    else
      not_approved_status
    end
  end

  def only_new_feature_review?
    decorated_feature_reviews.length == 1 &&
      decorated_feature_reviews[0].tickets.blank? &&
      decorated_feature_reviews[0].release_exception.blank?
  end

  def searching_status
    {
      status: 'pending',
      description: 'Searching for Feature Review',
    }
  end

  def not_found_status
    {
      status: 'failure',
      description: "No Feature Review found. Click 'Details' to create one.",
    }
  end

  def error_status
    {
      status: 'error',
      description: 'Something went wrong while relinking your PR to FR.',
    }
  end

  def approved_status
    {
      status: 'success',
      description: 'Approved Feature Review found',
    }
  end

  def reapproval_status
    {
      status: 'pending',
      description: 'Re-approval required for Feature Review',
    }
  end

  def not_approved_status
    {
      status: 'pending',
      description: 'Awaiting approval for Feature Review',
    }
  end

  def github
    @github ||= GithubClient.new(ShipmentTracker::GITHUB_REPO_STATUS_WRITE_TOKEN)
  end
end
