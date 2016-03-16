require 'events/base_event'
require 'snapshots/event_count'

require 'active_record'

module Repositories
  class Updater
    def self.from_rails_config
      new(Rails.configuration.repositories)
    end

    def initialize(repositories)
      @repositories = repositories
    end

    def run(repo_event_id_hash = {})
      repositories.each do |repository|
        run_for(repository, repo_event_id_hash[repository.table_name])
      end
    end

    def reset
      ActiveRecord::Base.transaction do
        all_tables.each do |table_name|
          truncate(table_name)
        end
      end
    end

    private

    attr_reader :repositories

    def run_for(repository, ceiling_id)
      ActiveRecord::Base.transaction do
        last_id = 0
        new_events_for(repository, ceiling_id).each do |event|
          last_id = event.id
          repository.apply(event)
        end
        update_count_for(repository, last_id) unless last_id == 0
      end
    end

    def new_events_for(repository, ceiling_id)
      Events::BaseEvent.between(last_id_for(repository), to_id: ceiling_id)
    end

    def last_id_for(repository)
      Snapshots::EventCount.find_by_snapshot_name(repository.table_name).try(:event_id) || 0
    end

    def update_count_for(repository, id)
      record = Snapshots::EventCount.find_or_create_by(snapshot_name: repository.table_name)
      record.event_id = id
      record.save!
    end

    def all_tables
      [Snapshots::EventCount.table_name].concat(repositories.map(&:table_name))
    end

    def truncate(table_name)
      ActiveRecord::Base.connection.execute("TRUNCATE #{table_name} RESTART IDENTITY")
    end
  end
end
