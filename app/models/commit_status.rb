require 'active_support/json'
require 'octokit'

require 'clients/github'
require 'factories/feature_review_factory'
require 'feature_review_with_statuses'
require 'repositories/deploy_repository'
require 'repositories/ticket_repository'

class CommitStatus
  def initialize
    @routes = Rails.application.routes.url_helpers
  end

  def update(full_repo_name:, sha:)
    feature_reviews = decorated_feature_reviews(sha)

    status, description = status_for(feature_reviews).values_at(:status, :description)

    target_url = target_url_for(full_repo_name: full_repo_name, sha: sha, feature_reviews: feature_reviews)

    post_status(full_repo_name, sha, { status: status, description: description }, target_url)
  end

  def reset(full_repo_name:, sha:)
    post_status(full_repo_name, sha, searching_status)
  end

  def error(full_repo_name:, sha:)
    post_status(full_repo_name, sha, error_status)
  end

  def not_found(full_repo_name:, sha:)
    post_status(full_repo_name, sha, not_found_status)
  end

  private

  def post_status(full_repo_name, sha, notification, target_url = nil)
    github.create_status(
      repo: full_repo_name,
      sha: sha,
      state: notification[:status],
      description: notification[:description],
      target_url: target_url,
    )
  end

  attr_reader :routes

  def decorated_feature_reviews(sha)
    tickets = Repositories::TicketRepository.new.tickets_for_versions([sha])
    feature_reviews = Factories::FeatureReviewFactory.new
                                                     .create_from_tickets(tickets)
                                                     .select { |fr| fr.versions.include?(sha) }
    feature_reviews.map do |feature_review|
      linked_tickets = tickets.select { |ticket| ticket.paths.include?(feature_review.path) }
      FeatureReviewWithStatuses.new(feature_review, tickets: linked_tickets)
    end
  end

  def target_url_for(full_repo_name:, sha:, feature_reviews:)
    repo_name = full_repo_name.split('/').last

    if feature_reviews.empty?
      url_to_autoprepared_feature_review(repo_name, sha)
    elsif feature_reviews.length == 1
      url_to_feature_review(feature_reviews.first.path)
    else
      url_to_search_feature_reviews(repo_name, sha)
    end
  end

  def url_to_autoprepared_feature_review(repo_name, sha, url_opts = {})
    last_staging_deploy = Repositories::DeployRepository.new.last_staging_deploy_for_version(sha)
    url_opts[:uat_url] = last_staging_deploy.server if last_staging_deploy
    url_opts[:apps] = { repo_name => sha }
    routes.feature_reviews_url(url_opts)
  end

  def url_to_feature_review(feature_review_path)
    routes.root_url.chomp('/') + feature_review_path
  end

  def url_to_search_feature_reviews(repo_name, sha, url_opts = {})
    url_opts[:application] = repo_name
    url_opts[:version] = sha
    routes.search_feature_reviews_url(url_opts)
  end

  def status_for(feature_reviews)
    if feature_reviews.empty?
      not_found_status
    elsif feature_reviews.any?(&:authorised?)
      approved_status
    elsif feature_reviews.any?(&:tickets_approved?)
      reapproval_status
    else
      not_approved_status
    end
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
