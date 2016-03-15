require 'active_record'

module Snapshots
  class Ticket < ActiveRecord::Base
    store_accessor :version_timestamps

    def self.full_text_search(query, limit: 5)
      Snapshots::Ticket.connection.select_all("
        SELECT summary, id, tsv
          FROM tickets, plainto_tsquery('#{query}') AS q
          WHERE (tsv @@ q) LIMIT #{limit};
      ").to_hash
    end
  end
end
