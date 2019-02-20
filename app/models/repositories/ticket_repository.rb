# frozen_string_literal: true

require 'events/jira_event'
require 'factories/feature_review_factory'
require 'git_repository_location'
require 'snapshots/ticket'
require 'ticket'

module Repositories
  class TicketRepository < Base
    def initialize(store = Snapshots::Ticket, git_repository_location: GitRepositoryLocation)
      @store = store
      @git_repository_location = git_repository_location
      @feature_review_factory = Factories::FeatureReviewFactory.new
    end

    def tickets_for_path(feature_review_path, at: nil)
      query = at ? store.arel_table['event_created_at'].lteq(at) : nil
      store
        .where('paths @> ARRAY[?]', feature_review_path)
        .where(id: store.select('MAX(id) as id').where(query).group(:key))
        .order('key, id DESC')
        .map { |t| Ticket.new(t.attributes) }
    end

    def tickets_for_versions(versions)
      store
        .where('versions && ARRAY[?]', versions)
        .where(id: store.select('MAX(id) as id').group(:key))
        .order('key, id DESC')
        .map { |t| Ticket.new(t.attributes) }
    end

    def apply(event)
      return unless event.is_a?(Events::JiraEvent) && event.issue?

      feature_reviews = feature_review_factory.create_from_text(event.comment)
      last_ticket = previous_ticket_data(event)

      return if last_ticket.empty? && feature_reviews.empty?

      update_keys(event)

      new_ticket = event.apply(last_ticket)
      store.create!(new_ticket)

      update_github_status_for([new_ticket, last_ticket]) if update_github_status?(event, feature_reviews)
    end

    private

    attr_reader :git_repository_location, :feature_review_factory

    def update_keys(event)
      store.where(key: event.changelog_old_key).update_all(key: event.changelog_new_key) if event.transfer?
    end

    def previous_ticket_data(event)
      key = event.transfer? ? event.changelog_old_key : event.key
      attrs = store.where(key: key).last&.attributes || {}
      attrs.except!('id')
    end

    def update_github_status?(event, feature_reviews)
      return false if Rails.configuration.data_maintenance_mode

      event.approval? || event.unapproval? || event.transfer? || feature_reviews.present?
    end

    def update_github_status_for(ticket_hashes)
      tickets = ticket_hashes.map { |ticket| Ticket.new(ticket) }

      array_of_app_versions = feature_review_factory.create_from_tickets(tickets).map(&:app_versions)

      array_of_app_versions.map(&:invert).reduce({}, :merge).each do |version, app_name|
        repository_location = git_repository_location.find_by_name(app_name)
        next unless repository_location

        CommitStatusUpdateJob.perform_later(
          full_repo_name: repository_location.full_repo_name,
          sha: version,
        )
      end
    end
  end
end
