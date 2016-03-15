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

    # def tickets_for_path(feature_review_path, at: nil)
    #   query = at ? store.arel_table['event_created_at'].lteq(at) : nil
    #   store
    #     .select('DISTINCT ON (key) *')
    #     .where('paths @> ARRAY[?]', feature_review_path)
    #     .where(query)
    #     .order('key, id DESC')
    #     .map { |t| Ticket.new(t.attributes) }
    # end
    #
    # def tickets_for_versions(versions)
    #   store
    #     .select('DISTINCT ON (key) *')
    #     .where('versions && ARRAY[?]::varchar[]', versions)
    #     .order('key, id DESC')
    #     .map { |t| Ticket.new(t.attributes) }
    # end

    def tickets_for_query(query)
      [
        { 'Jira Key' => 'ENG-2', 'Summary' => 'Make another task',
          'Description' => "As a User\r\n implement another task" },
        { 'Jira Key' => 'ENG-2', 'Summary' => 'Make another story',
          'Description' => "As a User\r\n implement another story" },
      ]
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
      attrs = store.where(key: key).last.try(:attributes) || {}
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
