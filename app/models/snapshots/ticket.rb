require 'active_record'

module Snapshots
  class Ticket < ActiveRecord::Base
    store_accessor :version_timestamps

    include PgSearch
  end
end
