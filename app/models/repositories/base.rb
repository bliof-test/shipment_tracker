# frozen_string_literal: true

module Repositories
  class Base
    attr_reader :store
    delegate :table_name, to: :store

    def identifier
      table_name
    end

    def last_applied_event_id
      Snapshots::EventCount.pointer_for(identifier)
    end
  end
end
