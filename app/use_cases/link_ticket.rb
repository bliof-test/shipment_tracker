require 'repositories/ticket_repository'
require 'clients/jira'

class LinkTicket
  include SolidUseCase

  steps :validate_id_format, :assert_not_linked, :post_comment

  def validate_id_format(args)
    return fail :invalid_key, message: invalid_key_message(args) unless /[A-Z][A-Z]+-\d*/ =~ args[:jira_key]
    continue(args)
  end

  def assert_not_linked(args)
    tickets = Repositories::TicketRepository.new.tickets_for_path(args[:feature_review_path])

    return fail :duplicate_key, message: duplicate_key_message(args) if tickets.any? { |ticket|
      ticket.key == args[:jira_key]
    }
    continue(args)
  end

  def post_comment(args)
    begin
      JiraClient.post_comment(args[:jira_key], jira_comment(args))
    rescue JiraClient::InvalidKeyError
      return fail :invalid_key, message: invalid_key_message(args)
    rescue StandardError => error
      Honeybadger.notify(error)
      return fail :post_failed, message: generic_error_message(args)
    end
    continue(success_message(args))
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
    "Feature Review was linked to #{args[:jira_key]}."\
    ' Refresh this page in a moment and the ticket will appear.'
  end

  def jira_comment(args)
    feature_review_url = "#{args[:root_url].chomp('/')}#{args[:feature_review_path]}"

    "[Feature ready for review|#{feature_review_url}]"
  end
end
