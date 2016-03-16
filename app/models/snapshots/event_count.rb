require 'active_record'

module Snapshots
  class EventCount < ActiveRecord::Base
    def self.repo_event_id_hash
      pluck(:snapshot_name, :event_id).to_h
    end
  end
end
