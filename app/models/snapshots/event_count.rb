# frozen_string_literal: true
require 'active_record'

module Snapshots
  class EventCount < ActiveRecord::Base
    class << self
      def global_event_pointer
        find_by_snapshot_name('global_event_pointer')&.event_id || 0
      end

      def global_event_pointer=(event_id)
        transaction do
          record = find_or_create_by(snapshot_name: 'global_event_pointer')
          record.event_id = event_id
          record.save!
        end

        event_id
      end

      def pointer_for(identifier)
        find_by(snapshot_name: identifier)&.event_id || 0
      end

      def update_pointer(identifier, event_id)
        event_count = find_or_initialize_by(snapshot_name: identifier)
        event_count.event_id = event_id
        event_count.save!
      end
    end
  end
end
