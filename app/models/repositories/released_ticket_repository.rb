# frozen_string_literal: true
require 'events/jira_event'
require 'factories/feature_review_factory'
require 'git_repository_loader'
require 'snapshots/released_ticket'
require 'released_ticket'

module Repositories
  class ReleasedTicketRepository
    def initialize(store = Snapshots::ReleasedTicket)
      @store = store
      @feature_review_factory = Factories::FeatureReviewFactory.new
      @git_repository_loader = GitRepositoryLoader.from_rails_config
    end

    attr_reader :store
    delegate :table_name, to: :store

    def tickets_for_query(query)
      store.search_for(query).map { |t| ReleasedTicket.new(t.attributes) }
    end

    def apply(event)
      if jira_issue?(event)
        snapshot_jira_event(event)
      elsif production_deploy?(event)
        snapshot_deploy_event(event)
      end
    end

    private

    attr_reader :feature_review_factory, :git_repository_loader

    def git_repository(app_name)
      git_repository_loader.load(app_name)
    end

    def snapshot_jira_event(event)
      feature_reviews = feature_review_factory.create_from_text(event.comment)

      if (record = store.find_by(key: event.key))
        record.update(build_ticket(event, feature_reviews, record.attributes))
      else
        store.create!(build_ticket(event, feature_reviews)) unless feature_reviews.empty?
      end
    end

    def snapshot_deploy_event(event)
      return unless event.version
      begin
        commit = git_repository(event.app_name).commit_for_version(event.version)

        tickets_for_versions(commit.associated_ids).each do |record|
          next if duplicate_deploy?(record.deploys, event)

          record.deploys << build_deploy_hash(event)
          record.save!
        end
      rescue GitRepositoryLoader::NotFound => e
        log_warning(e, event)
      end
    end

    def log_warning(error, event)
      Rails.logger.warn "Could not find the repository '#{event.app_name}' locally"
      Rails.logger.warn error.message
    end

    def duplicate_deploy?(deploys_for_record, event)
      deploys_for_record.any? { |deploy_hash|
        deploy_hash['version'] == event.version && deploy_hash['region'] == event.locale
      }
    end

    def build_deploy_hash(event)
      {
        app: event.app_name,
        deployed_at: event.created_at.strftime('%F %H:%M %Z'),
        github_url: GitRepositoryLocation.github_url_for_app(event.app_name),
        region: event.locale,
        version: event.version,
      }
    end

    def jira_issue?(event)
      event.is_a?(Events::JiraEvent) && event.issue?
    end

    def production_deploy?(event)
      event.is_a?(Events::DeployEvent) && event.environment == 'production'
    end

    def build_ticket(jira_event, feature_reviews = [], ticket_attrs = {})
      ticket_attrs.merge(
        key: jira_event.key,
        summary: jira_event.summary,
        description: jira_event.description,
        versions: merge_ticket_versions(ticket_attrs, feature_reviews),
      )
    end

    def merge_ticket_versions(ticket_attrs, feature_reviews)
      old_versions = ticket_attrs.fetch('versions', [])
      new_versions = feature_reviews.flat_map(&:versions)
      old_versions.concat(new_versions).uniq
    end

    def tickets_for_versions(versions)
      store.where('versions && ARRAY[?]::varchar[]', versions)
    end
  end
end
