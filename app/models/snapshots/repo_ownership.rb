# frozen_string_literal: true

require 'active_record'

module Snapshots
  class RepoOwnership < ApplicationRecord
    class << self
      def for(repo)
        app_name = repo.is_a?(String) ? repo : repo.name
        find_or_initialize_by(app_name: app_name)
      end
    end

    def owner_emails
      MailAddressList.new(repo_owners)
    end

    def approver_emails
      MailAddressList.new(repo_approvers)
    end
  end
end
