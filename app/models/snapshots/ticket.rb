# frozen_string_literal: true

require 'active_record'

module Snapshots
  class Ticket < ApplicationRecord
    store_accessor :version_timestamps
  end
end
