# frozen_string_literal: true
module RepoAdminsHelper
  def format_emails(admins = [])
    admins = Array.wrap(admins)

    RepoAdmin.to_mail_address_list(admins).addresses.map { |email|
      h(email.format)
    }.join(', ').html_safe
  end
end
