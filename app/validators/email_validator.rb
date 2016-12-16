# frozen_string_literal: true
class EmailValidator < ActiveModel::EachValidator
  EMAIL_REGEX = /([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})/i

  def validate_each(record, attribute, value)
    return if value =~ /\A#{EMAIL_REGEX}\z/i

    record.errors[attribute] << (options[:message] || 'is not an email')
  end
end
