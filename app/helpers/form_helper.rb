# frozen_string_literal: true

module FormHelper
  def form_errors(record)
    return if record.errors.blank?

    content_tag(:ul, class: 'list-group') do
      record.errors.full_messages.map { |error|
        content_tag(:li, class: 'list-group-item list-group-item-danger') do
          error
        end
      }.join("\n").html_safe
    end
  end
end
