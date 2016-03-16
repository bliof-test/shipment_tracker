require 'active_record'

module Snapshots
  class ReleasedTicket < ActiveRecord::Base
    include PgSearch

    IGNORE_DOCUMENT_LENGTH = 0

    pg_search_scope :search_for,
      against: { summary: 'A', description: 'D' },
      using: {
        tsearch: {
          prefix: true,
          dictionary: 'english',
          normalization: IGNORE_DOCUMENT_LENGTH,
          any_word: true, # false is default
          tsvector_column: 'tsv',
        },
      }
  end
end
