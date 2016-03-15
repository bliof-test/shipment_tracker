require 'active_record'

module Snapshots
  class Ticket < ActiveRecord::Base
    store_accessor :version_timestamps

    include PgSearch
    pg_search_scope :search_for, against: [:summary, :status]
  end
end
