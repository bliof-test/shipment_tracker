# frozen_string_literal: true

require 'events/release_exception_event'
require 'snapshots/release_exception'

module Repositories
  class ReleaseExceptionRepository < Base
    def initialize(store = Snapshots::ReleaseException)
      @store = store
    end

    def release_exception_for_application(app_name:, from_date: nil, to_date: nil)
      time_period_query = if from_date.present? && to_date.present?
                            store.arel_table['submitted_at'].between(from_date.beginning_of_day..to_date.end_of_day)
                          end

      store
        .where(time_period_query)
        .where('path like ?', "%#{app_name}%")
        .map { |result| ReleaseException.new(result.attributes) }
    end

    def release_exception_for(versions:, at: nil)
      submitted_at_query = at ? store.arel_table['submitted_at'].lteq(at) : nil

      store
        .where(submitted_at_query)
        .where('versions && ARRAY[?]', versions)
        .order('id DESC')
        .first
        .try { |result| ReleaseException.new(result.attributes) }
    end

    def apply(event)
      return unless event.is_a?(Events::ReleaseExceptionEvent)

      store.create!(
        repo_owner_id: event.repo_owner.id,
        approved: event.approved?,
        comment: event.comment,
        path: event.path,
        versions: prepared_versions(event.versions),
        submitted_at: event.created_at,
      )

      update_commit_status(event)
    end

    private

    def update_commit_status(event)
      event.app_versions.each do |app_name, version|
        CommitStatusUpdateJob.perform_later(
          full_repo_name: GitRepositoryLocation.find_by(name: app_name).full_repo_name,
          sha: version,
        )
      end
    end

    def prepared_versions(versions)
      versions.sort
    end
  end
end
