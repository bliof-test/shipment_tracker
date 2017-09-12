# frozen_string_literal: true
require 'mail'

module Forms
  class EditGitRepositoryLocationForm
    include ActiveModel::Model

    def initialize(repo:, current_user:, params: {})
      @repo = repo
      @params = params
      @current_user = current_user
      @required_checks = params[:required_checks]

      super(params)

      @repo_owners ||= ''
      @required_checks ||= []
    end

    attr_accessor :repo_owners, :required_checks
    attr_reader :repo, :params, :current_user

    validates :repo_owners, with: :validate_repo_owners, allow_blank: true
    validates :required_checks, with: :validate_required_checks, allow_nil: false

    alias git_repository_location repo

    def call
      return false unless valid?

      apply_repo_ownership_event
      apply_git_repo_location_event
    end

    def repo_owners_data
      if valid?
        RepoOwner.to_mail_address_list(repo_ownership_repository.owners_of(repo)).format.gsub(', ', "\n")
      else
        params[:repo_owners]
      end
    end

    private

    def repo_ownership_repository
      @repo_ownership_repository ||= Repositories::RepoOwnershipRepository.new
    end

    def git_repo_location_repository
      @git_repo_location_repository ||= Repositories::GitRepoLocationRepository.new
    end

    def owners_address_list
      @owners_address_list ||= parse_repo_owners
    end

    def required_checks_list_valid?
      @required_checks.all? { |check| GitRepositoryLocation::AVAILABLE_CHECKS.keys.include?(check) }
    end

    def parse_repo_owners
      address_list = repo_owners.split(/\n|,/).map(&:strip).select(&:present?).join(', ')

      MailAddressList.new(address_list)
    end

    def validate_repo_owners
      return if owners_address_list.valid?

      errors.add(:repo_owners, 'is invalid')
    end

    def validate_required_checks
      return if required_checks_list_valid?

      errors.add(:required_checks, 'is invalid')
    end

    def apply_repo_ownership_event
      event = Events::RepoOwnershipEvent.create!(
        details: {
          app_name: repo.name,
          repo_owners: owners_address_list.format(keep_brackets: true),
          email: current_user.email,
        },
      )

      repo_ownership_repository.apply(event)
    end

    def apply_git_repo_location_event
      event = Events::GitRepositoryLocationEvent.create!(
        details: {
          app_name: repo.name,
          required_checks: required_checks,
        },
      )

      git_repo_location_repository.apply(event)
    end
  end
end
