# frozen_string_literal: true
require 'events/jira_event'
require 'factories/feature_review_factory'
require 'git_repository_location'
require 'snapshots/ticket'
require 'ticket'

module Repositories
  class TicketRepository
    def initialize(store = Snapshots::Ticket, git_repository_location: GitRepositoryLocation)
      @store = store
      @git_repository_location = git_repository_location
      @feature_review_factory = Factories::FeatureReviewFactory.new
    end

    attr_reader :store
    delegate :table_name, to: :store

    def tickets_for_path(feature_review_path, at: nil)
      query = at ? store.arel_table['event_created_at'].lteq(at) : nil
      store
        .select('DISTINCT ON (key) *')
        .where('paths @> ARRAY[?]', feature_review_path)
        .where(query)
        .order('key, id DESC')
        .map { |t| Ticket.new(t.attributes) }
    end

    def tickets_for_versions(versions)
      store
        .select('DISTINCT ON (key) *')
        .where('versions && ARRAY[?]::varchar[]', versions)
        .order('key, id DESC')
        .map { |t| Ticket.new(t.attributes) }
    end

    def apply(event)
      return unless event.is_a?(Events::JiraEvent) && event.issue?

      feature_reviews = feature_review_factory.create_from_text(event.comment)

      last_ticket = previous_ticket_data(event.key)
      new_ticket = build_ticket(last_ticket, event, feature_reviews)
      store.create!(new_ticket)

      # TODO: extract to CommitStatusUpdater class
      update_github_status_for(new_ticket) if update_github_status?(event, feature_reviews)
    end

    private

    attr_reader :git_repository_location, :feature_review_factory

    def previous_ticket_data(key)
      attrs = store.where(key: key).last.try(:attributes) || {}
      attrs.except!('id')
    end

    def build_ticket(last_ticket, event, feature_reviews)
      last_ticket.merge(
        'key' => event.key,
        'summary' => event.summary,
        'status' => event.status,
        'paths' => merge_ticket_paths(last_ticket, feature_reviews),
        'event_created_at' => event.created_at,
        'versions' => merge_ticket_versions(last_ticket, feature_reviews),
        'approved_at' => merge_approved_at(last_ticket, event),
        'version_timestamps' => merge_version_timestamps(last_ticket, feature_reviews, event),
      )
    end

    def merge_version_timestamps(ticket, feature_reviews, event)
      old_version_timestamps = ticket.fetch('version_timestamps', {})
      new_version_timestamps = feature_reviews.flat_map(&:versions).each_with_object({}) { |version, hash|
        hash[version] = event.created_at # TODO: switch to datetime for JIRA time
      }
      new_version_timestamps.merge!(old_version_timestamps)
    end

    def merge_ticket_paths(ticket, feature_reviews)
      old_paths = ticket.fetch('paths', [])
      new_paths = feature_reviews.map(&:path)
      old_paths.concat(new_paths).uniq
    end

    def merge_ticket_versions(ticket, feature_reviews)
      old_versions = ticket.fetch('versions', [])
      new_versions = feature_reviews.flat_map(&:versions)
      old_versions.concat(new_versions).uniq
    end

    def merge_approved_at(last_ticket, event)
      return nil unless Ticket.new(status: event.status).approved?
      last_ticket['approved_at'] || event.created_at # TODO: switch to datetime for JIRA time
    end

    def update_github_status?(event, feature_reviews)
      return false if Rails.configuration.data_maintenance_mode
      event.approval? || event.unapproval? || feature_reviews.present?
    end

    def update_github_status_for(ticket_hash)
      ticket = Ticket.new(ticket_hash)
      array_of_app_versions = feature_review_factory.create_from_tickets([ticket]).map(&:app_versions)

      array_of_app_versions.map(&:invert).reduce({}, :merge).each do |version, app_name|
        repository_location = git_repository_location.find_by_name(app_name)
        CommitStatusUpdateJob.perform_later(
          full_repo_name: repository_location.full_repo_name,
          sha: version,
        ) if repository_location
      end
    end
  end
end
