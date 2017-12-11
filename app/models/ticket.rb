# frozen_string_literal: true
require 'virtus'

class Ticket
  include Virtus.value_object

  values do
    attribute :key, String
    attribute :summary, String, default: ''
    attribute :description, String, default: ''
    attribute :status, String, default: 'To Do'
    attribute :paths, Array, default: []
    attribute :approved_at, DateTime
    attribute :approved_by_email, String
    attribute :version_timestamps, Hash[String => DateTime]
    attribute :versions, Array, default: []
  end

  def authorisation_status(versions_under_review, apps_with_approver_emails = [])
    return 'Requires reapproval' if approved? && !authorised?(versions_under_review, apps_with_approver_emails)
    status
  end

  def approved?
    Rails.application.config.approved_statuses.include?(status)
  end

  def authorised?(versions_under_review, apps_with_approver_emails = [])
    return false if approved_at.nil? || !apps_with_approver_emails.all? { |_, emails|
      emails.include?(approved_by_email.downcase)
    }

    linked_at = versions_under_review.map { |v| version_timestamps[v] }.compact.min
    return false if linked_at.nil?
    approved_at >= linked_at
  end
end
