# frozen_string_literal: true
module RepoOwnersHelper
  def format_emails(owners = [])
    owners = Array.wrap(owners)

    RepoOwner.to_mail_address_list(owners).addresses.map { |email|
      h(email.format)
    }.join(', ').html_safe
  end
end
