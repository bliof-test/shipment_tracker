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

    WHITELIST_DOMAINS = %w(github.com).freeze
    REPO_URI_REGEX = %r{((file|git|ssh|http(s)?)|(git@[\w\.]+))(:(//)?)([\w\.@\:/\-~]+)(\.git)?(/)?}
    DEFAULT_SELECTED_TOKENS = %w(circleci deploy).freeze

    attr_reader :uri, :token_types

    def initialize(uri, token_types)
      @uri = uri
      @token_types = token_types
    end

    def valid?
      valid_uri? && repo_accessible? && errors.empty?
    end

    def self.default_token_types
      @default_token_types ||= Token.sources.map { |token_src|
        value = DEFAULT_SELECTED_TOKENS.include? token_src.endpoint
        { id: token_src.endpoint, name: token_src.name, value: value }
      }
    end

    private

    attr_reader :parsed_uri

    def parsed_uri
      @parsed_uri ||= GitCloneUrl.parse(uri)
    end

    def valid_uri?
      if uri.blank?
        errors.add(:git_uri, 'cannot be empty')
        return false
      end

      unless uri =~ REPO_URI_REGEX
        errors.add(:git_uri, 'must be valid Git URI, e.g. git@github.com:owner/repo.git')
        return false
      end

      unless valid_hostname?
        errors.add(:git_uri, "domain should be one of #{WHITELIST_DOMAINS.join(', ')}")
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

    def valid_hostname?
      WHITELIST_DOMAINS.include?(parsed_uri.host)
    rescue URI::InvalidComponentError
      false
    end

    def github
      @github_client ||= GithubClient.new(ShipmentTracker::GITHUB_REPO_READ_TOKEN)
    end
  end
end
