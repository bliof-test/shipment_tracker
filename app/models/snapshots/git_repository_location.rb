# frozen_string_literal: true

require 'active_record'

module Snapshots
  class GitRepositoryLocation < ApplicationRecord
    class << self
      def for(app_name)
        find_or_initialize_by(name: app_name)
      end
    end
  end
end
