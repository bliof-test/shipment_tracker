# frozen_string_literal: true

require 'clients/github'
require 'git_clone_url'
require 'token'

require 'active_model'

module Forms
  class RepositoryLocationsForm
    extend ActiveModel::Naming
    include ActiveModel::Validations

    def to_key
      nil
    end

    WHITELIST_DOMAINS = %w[github.com].freeze
    REPO_GIT_URI_REGEX = %r{\A(git)@([\w\.]+):([\w\.\/\-]+)(\.git)\z}
    REPO_VCS_URI_REGEX = %r{\A(file|git|ssh|http(s)?)(://)([\w\.@/\-~]+)(\:[0-9]{1,5})?(/[\w\.\-]+)+(\.git)?(/)?\z}
    DEFAULT_SELECTED_TOKENS = %w[circleci deploy].freeze

    attr_reader :uri, :token_types

    def initialize(uri)
      @uri = uri
    end

    def valid?
      valid_uri? && repo_accessible? && errors.empty?
    end

    def self.default_token_types
      @default_token_types ||= Token.sources.map { |token_src|
        value = DEFAULT_SELECTED_TOKENS.include?(token_src.endpoint)
        { id: token_src.endpoint, name: token_src.name, value: value }
      }
    end

    private

    def parsed_uri
      @parsed_uri ||= GitCloneUrl.parse(uri)
    end

    def valid_uri?
      if uri.blank?
        errors.add(:base, 'Git URI cannot be empty')
        return false
      end

      unless valid_uri_format?
        errors.add(:base, "Not a valid Git URI '#{uri}'")
        return false
      end

      unless valid_hostname?
        errors.add(:base, "Git URI did not contain a whitelisted domain: #{WHITELIST_DOMAINS.join(', ')}")
        return false
      end

      true
    end

    def repo_accessible?
      unless github.repo_accessible?(uri)
        errors.add(:repository, 'is not accessible either due to permissions or it does not exist')
        return false
      end

      true
    end

    def valid_uri_format?
      if uri.start_with?('git@')
        REPO_GIT_URI_REGEX =~ uri
      else
        REPO_VCS_URI_REGEX =~ uri
      end
    end

    def valid_hostname?
      WHITELIST_DOMAINS.include?(parsed_uri.host)
    rescue URI::InvalidComponentError
      false
    end

    def github
      @github ||= GithubClient.new(ShipmentTracker::GITHUB_REPO_READ_TOKEN)
    end
  end
end
