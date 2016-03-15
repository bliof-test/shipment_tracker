require 'active_record'

module Snapshots
  class Ticket < ActiveRecord::Base
    store_accessor :version_timestamps

    include PgSearch

    IGNORE_DOCUMENT_LENGTH = 0

    pg_search_scope :search_for,
                    against: { summary: 'A', status: 'D' },
                    using: {
                      tsearch: {
                        prefix: true,
                        negation: true,
                        dictionary: 'english',
                        normalization: IGNORE_DOCUMENT_LENGTH,
                        any_world: false, # false is default
                      }
                    }
  end
end
