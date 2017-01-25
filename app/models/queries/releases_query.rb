# frozen_string_literal: true
require 'release'

module Queries
  class ReleasesQuery
    attr_reader :pending_releases, :deployed_releases

    def initialize(per_page:, region:, git_repo:, app_name:, commits: nil)
      @commits = commits
      @per_page = per_page
      @region = region
      @git_repository = git_repo
      @app_name = app_name

      @deploy_repository = Repositories::DeployRepository.new
      @ticket_repository = Repositories::TicketRepository.new
      @exception_repository = Repositories::ReleaseExceptionRepository.new
      @feature_review_factory = Factories::FeatureReviewFactory.new

      @pending_releases = []
      @deployed_releases = []

      build_and_categorize_releases
    end

    def versions
      commits.map(&:id)
    end

    private

    attr_reader :app_name, :deploy_repository, :feature_review_factory

    def production_deploys
      @production_deploys ||= deploy_repository
                              .deploys_for_versions(versions, environment: 'production', region: @region)
    end

    def commits
      @commits ||= @git_repository.recent_commits_on_main_branch(@per_page)
    end

    def feature_reviews
      @feature_reviews ||= feature_review_factory.create_from_tickets(tickets)
    end

    def tickets
      @tickets ||= @ticket_repository.tickets_for_versions(associated_versions)
    end

    def release_exception(versions)
      @exception_repository.release_exception_for(versions: versions)
    end

    def associated_versions
      commits.flat_map(&:associated_ids).uniq
    end

    def production_deploy_for_commit(commit)
      production_deploys.detect { |deployment|
        deployment.version == commit.id
      }
    end

    def build_and_categorize_releases
      deployed = false
      commits.each { |commit|
        deploy_for_commit = production_deploy_for_commit(commit)
        deployed = true if deploy_for_commit # A deploy means all subsequent (earlier) commits are deployed.
        if deployed
          @deployed_releases << create_release_from(commit: commit, deploy: deploy_for_commit)
        else
          @pending_releases << create_release_from(commit: commit)
        end
      }
    end

    def create_release_from(commit:, deploy: nil)
      decorated_feature_reviews = feature_reviews
                                  .select { |fr| (fr.versions & commit.associated_ids).present? }
                                  .map { |fr| decorate_feature_review(fr) }

      if decorated_feature_reviews.empty?
        new_feature_review = feature_review_factory.create_from_version(app_name, commit.id)
        decorated_feature_reviews << decorate_feature_review(new_feature_review)
      end

      Release.new(
        commit: commit,
        production_deploy_time: deploy&.deployed_at,
        subject: commit.subject_line,
        feature_reviews: decorated_feature_reviews,
        deployed_by: deploy&.deployed_by,
      )
    end

    def decorate_feature_review(feature_review)
      FeatureReviewWithStatuses.new(
        feature_review,
        tickets: tickets.select { |t| t.paths.include?(feature_review.path) },
        release_exception: release_exception(feature_review.versions),
      )
    end
  end
end
