# frozen_string_literal: true
require 'feature_review_with_statuses'
require 'repositories/build_repository'
require 'repositories/manual_test_repository'
require 'repositories/ticket_repository'

module Queries
  class FeatureReviewQuery
    attr_reader :feature_review_with_statuses

    def initialize(feature_review, at:)
      @build_repository = Repositories::BuildRepository.new
      @manual_test_repository = Repositories::ManualTestRepository.new
      @ticket_repository = Repositories::TicketRepository.new
      @release_exception_repository = Repositories::ReleaseExceptionRepository.new
      @feature_review = feature_review
      @time = at

      build_feature_review_with_statuses
    end

    private

    attr_reader :build_repository, :manual_test_repository, :release_exception_repository,
      :integration_test_repository, :ticket_repository, :feature_review, :time

    def build_feature_review_with_statuses
      @feature_review_with_statuses = FeatureReviewWithStatuses.new(
        feature_review,
        unit_test_results: unit_test_results,
        integration_test_results: integration_test_results,
        qa_submissions: qa_submissions,
        release_exception: release_exception,
        tickets: tickets,
        at: time,
      )
    end

    def unit_test_results
      build_repository.unit_test_results_for(
        apps: feature_review.app_versions,
        at: time,
      )
    end

    def integration_test_results
      build_repository.integration_test_results_for(
        apps: feature_review.app_versions,
        at: time,
      )
    end

    def qa_submissions
      manual_test_repository.qa_submissions_for(
        versions: feature_review.related_app_versions.values.flatten,
        at: time,
      )
    end

    def release_exception
      release_exception_repository.release_exception_for(
        versions: feature_review.versions,
        at: time,
      )
    end

    def tickets
      ticket_repository.tickets_for_path(feature_review.path, at: time)
    end
  end
end
