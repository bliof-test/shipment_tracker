# frozen_string_literal: true
require 'events/manual_test_event'
require 'qa_submission'
require 'snapshots/manual_test'

module Repositories
  class ManualTestRepository < Base
    def initialize(store = Snapshots::ManualTest)
      @store = store
    end

    def qa_submissions_for(versions:, at: nil)
      query = at ? table['created_at'].lteq(at) : nil
      store
        .where(query)
        .where('versions && ?', prepared_versions(versions))
        .order('id ASC')
        .map { |manual_test| create_qa_submission(manual_test) }
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

    def prepared_versions(versions)
      "{#{versions.sort.join(',')}}"
    end

    def table
      store.arel_table
    end

    def create_qa_submission(manual_test)
      manual_test.try { |result| QaSubmission.new(result.attributes) }
    end
  end
end
