class SetTheGlobalEventPointer < ActiveRecord::Migration[4.2]
  module Events
    class BaseEvent < ActiveRecord::Base
      self.table_name = 'events'
    end
  end

  module Snapshots
    class EventCount < ActiveRecord::Base
    end
  end

  def up
    record = Snapshots::EventCount.create!(
      snapshot_name: 'global_event_pointer',
      event_id: Events::BaseEvent.last.try(:id) || 0,
    )

    say "Global Event Pointer (last applied event id): #{record.event_id}"
  end

  def down
    Snapshots::EventCount.find_by(snapshot_name: 'global_event_pointer')&.destroy
  end
end
