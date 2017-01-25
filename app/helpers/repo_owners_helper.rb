# frozen_string_literal: true
module RepoOwnersHelper
  def format_owner_emails(owners = [])
    owners = Array.wrap(owners)

    RepoOwner.to_mail_address_list(owners).addresses.map { |email|
      content_tag :span, h(email.format), class: 'text-nowrap'
    }.join(', ').html_safe
  end
end
