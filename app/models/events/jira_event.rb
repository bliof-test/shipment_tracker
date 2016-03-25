# frozen_string_literal: true
require 'events/base_event'

module Events
  class JiraEvent < Events::BaseEvent
    def datetime
      Time.zone.at(timestamp)
    end

    def key
      details.fetch('issue').fetch('key')
    end

    def issue?
      details.fetch('webhookEvent', '').start_with?('jira:issue_')
    end

    def issue_id
      details.fetch('issue').fetch('id')
    end

    def summary
      details.fetch('issue').fetch('fields').fetch('summary')
    end

    def description
      details.fetch('issue').fetch('fields').fetch('description')
    end

    def status
      details.fetch('issue').fetch('fields').fetch('status').fetch('name')
    end

    def comment
      details.fetch('comment', {}).fetch('body', '')
    end

    def approval?
      status_item &&
        !approved_status?(status_item['fromString']) &&
        approved_status?(status_item['toString'])
    end

    def unapproval?
      status_item &&
        approved_status?(status_item['fromString']) &&
        !approved_status?(status_item['toString'])
    end

    private

    def timestamp
      if details['timestamp']
        seconds_since_epoch
      else
        created_at
      end
    end

    def seconds_since_epoch
      details['timestamp'] / 1000
    end

    def status_item
      @status_item ||= changelog_items.find { |item| item['field'] == 'status' }
    end

    def changelog_items
      details.fetch('changelog', 'items' => []).fetch('items')
    end

    def approved_status?(status)
      Rails.application.config.approved_statuses.include?(status)
    end
  end
end
