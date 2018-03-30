# frozen_string_literal: true

class RepoAdmin < ActiveRecord::Base
  class << self
    def to_mail_address_list(owners)
      MailAddressList.new(owners.map { |owner| { name: owner.name, email: owner.email } })
    end
  end

  validates :email, presence: true, uniqueness: true, email: true

  def owner_of?(repo)
    repo.owners.include?(self)
  end
end
