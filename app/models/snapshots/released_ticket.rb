require 'active_record'

module Snapshots
  class ReleasedTicket < ActiveRecord::Base
    def self.create_or_update(ticket)
      if ticket['id']
        record = find(ticket['id'])
        record.update_attributes(ticket.except!('id'))
      else
        create(ticket)
      end
    end
  end
end
