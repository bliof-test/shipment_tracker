# frozen_string_literal: true
require 'events/release_exception_event'
require 'snapshots/release_exception'

module Repositories
  class ReleaseExceptionRepository
    def initialize(store = Snapshots::ReleaseException)
      @store = store
    end

    attr_reader :store
    delegate :table_name, to: :store

    def release_exception_for(versions:, at: nil)
      submitted_at_query = at ? table['submitted_at'].lteq(at) : nil

      store
        .where(submitted_at_query)
        .where(table['versions'].eq(prepared_versions(versions)))
        .where('versions @> ARRAY[?]', versions)
        .order('id DESC')
        .first
        .try { |result| ReleaseException.new(result.attributes) }
    end

    def apply(event)
      return unless event.is_a?(Events::ReleaseExceptionEvent) && valid_repo_owner?(event)

      store.create!(
        repo_owner_id: event.repo_owner.id,
        approved: event.approved?,
        comment: event.comment,
        versions: prepared_versions(event.versions),
        submitted_at: event.created_at,
      )
    end

    private

    def valid_repo_owner?(event)
      event.git_repos.any? do |git_repo|
        event.repo_owner.owner_of?(git_repo)
      end
    end

    def prepared_versions(versions)
      versions.sort
    end

    def table
      store.arel_table
    end
  end
end
