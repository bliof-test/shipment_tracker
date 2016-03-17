require 'events/jira_event'
require 'factories/feature_review_factory'
require 'snapshots/released_ticket'
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
      if event.is_a?(Events::JiraEvent) && event.issue?
        record = store.find_or_create_by('key' => event.key)
        # TODO: create FR from ticket, extract and store versions present in ticket
        record.update_attributes(build_ticket(record.attributes, event))
      elsif event.is_a?(Events::DeployEvent) && event.environment == 'production'
        # TODO: find correct released_ticket record(s) to populate the deploys column
      end
    end

    private

    attr_reader :store, :feature_review_factory

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
