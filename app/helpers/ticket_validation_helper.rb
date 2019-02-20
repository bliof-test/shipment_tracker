# frozen_string_literal: true

# This helper relies on gem SolidUseCase
module TicketValidationHelper
  def validate_id_format(args)
    return fail :invalid_key, message: invalid_key_message(args) unless /[A-Z][\dA-Z]+-\d+/ =~ args[:jira_key]

    continue(args)
  end
end
