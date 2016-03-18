require 'events/jira_event'
require 'factories/feature_review_factory'
require 'snapshots/released_ticket'
require 'ticket'

module Repositories
  class ReleasedTicketRepository
    def initialize(store = Snapshots::ReleasedTicket)
      @store = store
      @feature_review_factory = Factories::FeatureReviewFactory.new
    end

    delegate :table_name, to: :store

    def tickets_for_query(query)
      store.search_for(query).map { |t| Ticket.new(t.attributes) }
    end

    def apply(event)
      if jira_issue?(event)
        feature_reviews = feature_review_factory.create_from_text(event.comment)
        return if feature_reviews.empty?

        if (record = store.find_by(key: event.key))
          record.update(build_ticket(record.attributes, event, feature_reviews))
        else
          store.create!(build_ticket({}, event, feature_reviews))
        end
      elsif production_deploy?(event)
        records = tickets_for_version(event.version)

        records.each do |record|
          record.update(build_ticket_for_deploy(record.attributes, event))
        end
      end
    end

    private

    attr_reader :store, :feature_review_factory

    def jira_issue?(event)
      event.is_a?(Events::JiraEvent) && event.issue?
    end

    def production_deploy?(event)
      event.is_a?(Events::DeployEvent) && event.environment == 'production'
    end

    def build_ticket(ticket_attrs, jira_event, feature_reviews)
      ticket_attrs.merge(
        key: jira_event.key,
        summary: jira_event.summary,
        description: jira_event.description,
        versions: merge_ticket_versions(ticket_attrs, feature_reviews),
      )
    end

    def build_ticket_for_deploy(ticket_attrs, deploy_event)
      ticket_attrs.merge(deploys: merge_deploys(ticket_attrs, deploy_event))
    end

    def merge_ticket_versions(ticket_attrs, feature_reviews)
      old_versions = ticket_attrs.fetch('versions', [])
      new_versions = feature_reviews.flat_map(&:versions)
      old_versions.concat(new_versions).uniq
    end

    def merge_deploys(ticket_attrs, deploy_event)
      old_deploys = ticket_attrs.fetch('deploys', [])
      new_deploy = {
        'app' => deploy_event.app_name,
        'version' => deploy_event.version,
        'deployed_at' => deploy_event.created_at.strftime('%F %H:%M%:z'),
      }

      old_deploys << new_deploy
      old_deploys.uniq
    end

    def tickets_for_version(version)
      # TODO: put unique clause on the key column and index
      store.where('versions @> ARRAY[?]::varchar[]', version)
    end
  end
end
