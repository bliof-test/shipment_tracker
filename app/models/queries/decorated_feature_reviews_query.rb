# frozen_string_literal: true

module Queries
  class DecoratedFeatureReviewsQuery
    attr_reader :app_name, :commits, :feature_review_factory

    def initialize(app_name, commits)
      @app_name = app_name
      @commits = commits
      @release_exception_repository = Repositories::ReleaseExceptionRepository.new
      @ticket_repository = Repositories::TicketRepository.new
      @feature_review_factory = Factories::FeatureReviewFactory.new
    end

    def get(commit = commits.first)
      feature_reviews_for_commit(commit).map { |fr| decorate_feature_review(fr, commit) }
    end

    private

    def tickets
      @tickets ||= @ticket_repository.tickets_for_versions(associated_versions)
    end

    def associated_versions
      commits.flat_map(&:associated_ids).uniq
    end

    def feature_reviews_with_tickets
      @feature_reviews_with_tickets ||= feature_review_factory.create_from_tickets(tickets)
    end

    def release_exception(commit)
      release_exception_repository.release_exception_for(versions: commit.associated_ids)
    end

    def feature_reviews_for_commit(commit)
      commit_feature_reviews = feature_reviews_with_tickets_for_commit(commit)

      if commit_feature_reviews.empty?
        release_exception = release_exception(commit)

        if release_exception.present?
          commit_feature_reviews << feature_review_factory.create_from_url_string(release_exception.path)
        end
      end

      if commit_feature_reviews.empty?
        commit_feature_reviews << feature_review_factory.create_from_apps(app_name => commit.id)
      end

      commit_feature_reviews
    end

    def feature_reviews_with_tickets_for_commit(commit)
      feature_reviews_with_tickets.select { |fr|
        (fr.versions & commit.associated_ids).present?
      }
    end

    def decorate_feature_review(feature_review, commit)
      FeatureReviewWithStatuses.new(
        feature_review,
        tickets: tickets.select { |t| t.paths.include?(feature_review.path) },
        release_exception: release_exception(commit),
      )
    end

    attr_reader :release_exception_repository, :ticket_repository
  end
end
