# frozen_string_literal: true
require 'events/jira_event'
require 'factories/feature_review_factory'
require 'git_repository_loader'
require 'snapshots/released_ticket'
require 'released_ticket'
require 'snapshots/deploy'

module Repositories
  class ReleasedTicketRepository
    def initialize(store = Snapshots::ReleasedTicket)
      @store = store
      @deploy_store = Snapshots::Deploy
      @feature_review_factory = Factories::FeatureReviewFactory.new
      @git_repository_loader = GitRepositoryLoader.from_rails_config
    end

    attr_reader :store
    delegate :table_name, to: :store

    def tickets_for_query(query_text:, versions:, per_page: ShipmentTracker::NUMBER_OF_TICKETS_TO_DISPLAY)
      query = if versions.present?
                tickets_for_versions(versions)
              else
                store
              end

      query = query.search_for(query_text) unless query_text.blank?
      query = query.limit(per_page)
      query.map { |t| ReleasedTicket.new(t.attributes) }
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
        last_deploy = latest_production_deploy(event.app_name, event.locale, event.created_at)
        released_commits = released_commits(event.app_name, event.version, last_deploy&.version)
        released_commits.each do |commit|
          update_ticket_deploy_data(event, commit)
        end
      rescue GitRepositoryLoader::NotFound,
             GitRepository::CommitNotValid,
             GitRepository::CommitNotFound => e
        log_warning(e, event)
      end
    end

    def update_ticket_deploy_data(event, commit)
      tickets_for_versions(commit.associated_ids).each do |ticket_record|
        next if duplicate_deploy?(ticket_record.deploys, event)
        ticket_record.deploys << build_deploy_hash(event, commit.id)
        ticket_record.versions << commit.id unless ticket_record.versions.include?(commit.id)
        ticket_record.save!
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

    def build_deploy_hash(event, version)
      {
        app: event.app_name,
        deployed_at: event.created_at.strftime('%F %H:%M %Z'),
        github_url: GitRepositoryLocation.github_url_for_app(event.app_name),
        region: event.locale,
        version: version,
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

    def released_commits(app_name, current_version, previous_version = nil)
      git_repo = git_repository(app_name)
      if previous_version
        git_repo.commits_between(previous_version, current_version, simplify: true)
      else
        [git_repo.commit_for_version(current_version)]
      end
    end

    def latest_production_deploy(app_name, region, event_date)
      @deploy_store.where(app_name: app_name, environment: 'production', region: region)
                   .where('event_created_at < ?', event_date)
                   .order(id: 'desc')
                   .limit(1)
                   .first
    end
  end
end
