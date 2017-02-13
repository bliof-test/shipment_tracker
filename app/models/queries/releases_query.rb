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
      Release.new(
        commit: commit,
        production_deploy_time: deploy&.deployed_at,
        subject: commit.subject_line,
        feature_reviews: decorated_feature_reviews_from(commit),
        deployed_by: deploy&.deployed_by,
      )
    end

    def decorated_feature_reviews_from(commit)
      decorated_feature_reviews_query.get(commit)
    end

    def decorated_feature_reviews_query
      @decorated_feature_reviews_query ||= DecoratedFeatureReviewsQuery.new(app_name, commits)
    end
  end
end
