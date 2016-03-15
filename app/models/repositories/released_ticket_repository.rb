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

    def tickets_for_query(_query)
      results = store.all.map { |t| Ticket.new(t.attributes) }
      # TODO: remove filter selection below [..]
      results.any? ? results[1..2].reverse : results
    end

    def apply(event)
      return unless event.is_a?(Events::JiraEvent) && event.issue?

      last_ticket = previous_ticket_data(event.key)
      new_ticket = build_ticket(last_ticket, event)
      store.create_or_update(new_ticket)
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
