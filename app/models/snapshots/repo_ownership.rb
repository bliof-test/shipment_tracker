# frozen_string_literal: true
require 'active_record'

module Snapshots
  class RepoOwnership < ActiveRecord::Base
    class << self
      def for(repo)
        find_or_initialize_by(app_name: repo.name)
      end
    end

    def owner_emails
      MailAddressList.new(repo_owners)
    end
  end
end
