# frozen_string_literal: true
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

    attr_accessor :repositories

    def recreate(upto_event: nil)
      reset
      run(apply_to_all: true, upto_event: upto_event)
    end

    def run(apply_to_all: false, upto_event: nil)
      repositories_to_use = filter_repositories(apply_to_all: apply_to_all)

      new_events(upto_event: upto_event).each do |event|
        ActiveRecord::Base.transaction do
          repositories_to_use.each do |repository|
            apply repository: repository, event: event
          end

          Snapshots::EventCount.global_event_pointer = event.id
        end
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

    def apply(repository:, event:)
      Rails.logger.info "[#{Time.current}] Apply events for #{repository.class} - #{repository.table_name}"
      repository.apply(event)
      Snapshots::EventCount.update_pointer(repository.identifier, event.id)
    end

    def filter_repositories(apply_to_all: false)
      if apply_to_all
        repositories
      else
        repositories_that_do_not_run_in_the_background = [
          Repositories::RepoOwnershipRepository,
        ]

        repositories.reject { |r| repositories_that_do_not_run_in_the_background.include?(r.class) }
      end
    end

    def new_events(upto_event: nil)
      Events::BaseEvent.between(
        Snapshots::EventCount.global_event_pointer,
        to_id: upto_event || Events::BaseEvent.last&.id,
      )
    end

    def all_tables
      [Snapshots::EventCount.table_name].concat(repositories.map(&:table_name))
    end

    def truncate(table_name)
      ActiveRecord::Base.connection.execute("TRUNCATE #{table_name} RESTART IDENTITY")
    end
  end
end
