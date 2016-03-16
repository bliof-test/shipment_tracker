require 'events/jira_event'
require 'factories/feature_review_factory'
require 'git_repository_location'
require 'snapshots/ticket'
require 'ticket'

module Repositories
  class ReleasedTicketRepository
    def initialize(store = Snapshots::ReleasedTicket)
      @store = store
    end

    delegate :table_name, to: :store

    def tickets_for_query(query)
      store.search_for(query).map { |t| Ticket.new(t.attributes) }
    end

    def apply(event)
      return unless event.is_a?(Events::JiraEvent) && event.issue?

      record = store.find_or_create_by('key' => event.key)
      record.update_attributes(build_ticket(record.attributes, event))
    end

    private

    attr_reader :store, :git_repository_location, :feature_review_factory

    def previous_ticket_data(key)
      store.where(key: key).last.try(:attributes) || {}
    end

    def build_ticket(last_ticket, event)
      last_ticket.merge(
        'key' => event.key,
        'summary' => event.summary,
        'description' => event.description,
      )
    end
  end
end
