require 'events/manual_test_event'
require 'qa_submission'
require 'snapshots/manual_test'

module Repositories
  class ManualTestRepository
    def initialize(store = Snapshots::ManualTest)
      @store = store
    end

    delegate :table_name, to: :store

    def qa_submission_for(versions:, at: nil)
      qa_submission(versions, at)
    end

    def apply(event)
      return unless event.is_a?(Events::ManualTestEvent)

      store.create!(
        email: event.email,
        accepted: event.accepted?,
        comment: event.comment,
        versions: prepared_versions(event.versions),
        created_at: event.created_at,
      )
    end

    private

    attr_reader :store

    def qa_submission(versions, at)
      query = at ? table['created_at'].lteq(at) : nil
      store
        .where(query)
        .where(table['versions'].eq(prepared_versions(versions)))
        .order('id DESC')
        .first
        .try { |result| QaSubmission.new(result.attributes) }
    end

    def prepared_versions(versions)
      versions.sort
    end

    def table
      store.arel_table
    end
  end
end
