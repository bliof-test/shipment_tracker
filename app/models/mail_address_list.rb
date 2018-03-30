# frozen_string_literal: true

require 'mail'

class MailAddressList
  extend Forwardable

  def_delegator :address_list, :addresses
  def_delegator :addresses, :each

  def initialize(addresses = nil)
    @raw_addresses =
      case addresses
      when String
        addresses
      when Array
        addresses.map { |current|
          name = current[:name]
          email = current.fetch(:email)

          name.present? ? "#{name} <#{email}>" : email
        }.join(', ')
      else
        ''
      end
  end

  def valid?
    address_list.addresses.all? do |email|
      email.address =~ /\A#{EmailValidator::EMAIL_REGEX}\z/i
    end
  rescue StandardError => _
    false
  end

  def format(keep_brackets: false)
    address_list.addresses.map { |email|
      result = email.format

      if keep_brackets && email.raw == "<#{result}>"
        email.raw
      else
        result
      end
    }.join(', ')
  end

  def include?(email_address)
    addresses.map(&:address).include?(email_address)
  end

  private

  attr_reader :raw_addresses

  def address_list
    @address_list ||= Mail::AddressList.new(raw_addresses)
  end
end
