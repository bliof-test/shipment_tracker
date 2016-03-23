# frozen_string_literal: true
require 'active_record'

module Snapshots
  class ReleasedTicket < ActiveRecord::Base
    include PgSearch

    validates :key, uniqueness: true

    IGNORE_DOCUMENT_LENGTH = 0

    pg_search_scope :search_for,
      against: { deploys: 'A', summary: 'B', description: 'D' },
      using: {
        tsearch: {
          prefix: true,
          dictionary: 'english',
          normalization: IGNORE_DOCUMENT_LENGTH,
          any_word: true,
          tsvector_column: 'tsv',
        },
      }
  end
end
