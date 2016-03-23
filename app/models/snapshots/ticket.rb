# frozen_string_literal: true
require 'active_record'

module Snapshots
  class Ticket < ActiveRecord::Base
    store_accessor :version_timestamps
  end
end
