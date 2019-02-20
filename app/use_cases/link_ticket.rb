# frozen_string_literal: true

require 'repositories/ticket_repository'
require 'clients/jira'

class LinkTicket
  include SolidUseCase
  include TicketValidationHelper

  COMMENT_LABEL = 'Feature ready for review'

  steps :validate_id_format, :assert_not_linked, :post_comment

  class << self
    def build_comment(url)
      "[#{COMMENT_LABEL}|#{url}]"
    end
  end

  def assert_not_linked(args)
    tickets = Repositories::TicketRepository.new.tickets_for_path(args[:feature_review_path])

    has_links = tickets.any? { |ticket| ticket.key == args[:jira_key] }
    return fail :duplicate_key, message: duplicate_key_message(args) if has_links

    continue(args)
  end

  def post_comment(args)
    feature_review_url = "#{args[:root_url].chomp('/')}#{args[:feature_review_path]}"

    JiraClient.post_comment(args[:jira_key], self.class.build_comment(feature_review_url))
    continue(success_message(args))
  rescue JiraClient::InvalidKeyError
    fail :invalid_key, message: invalid_key_message(args)
  rescue StandardError => error
    Honeybadger.notify(error)
    fail :post_failed, message: generic_error_message(args)
  end

  private

  def invalid_key_message(args)
    "Failed to link #{args[:jira_key]}. Please check that the ticket ID is correct."
  end

  def duplicate_key_message(args)
    "Failed to link #{args[:jira_key]}. Duplicate tickets should not be added."
  end

  def generic_error_message(args)
    "Failed to link #{args[:jira_key]}. Something went wrong."
  end

  def success_message(args)
    "Feature Review was linked to #{args[:jira_key]}. Refresh this page in a moment and the ticket will appear."
  end
end
