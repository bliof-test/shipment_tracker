# frozen_string_literal: true
require 'mail'

module Forms
  class EditGitRepositoryLocationForm
    include ActiveModel::Model

    def initialize(repo:, current_user:, params: {})
      @repo = repo
      @params = params
      @current_user = current_user

      super(params)

      @repo_owners ||= ''
      @repo_approvers ||= ''
    end

    attr_accessor :repo_owners, :repo_approvers
    attr_reader :repo, :params, :current_user

    validates :repo_owners, with: :validate_repo_owners, allow_blank: true
    validates :repo_approvers, with: :validate_repo_approvers, allow_blank: true

    alias git_repository_location repo

    def call
      return false unless valid?

      event = Events::RepoOwnershipEvent.create!(
        details: {
          app_name: repo.name,
          repo_owners: owners_address_list.format(keep_brackets: true),
          repo_approvers: approvers_address_list.format(keep_brackets: true),
          email: current_user.email,
        },
      )

      repo_ownership_repository.apply(event)
    end

    def repo_owners_data
      if valid?
        mail_address_list(repo_ownership_repository.owners_of(repo))
      else
        params[:repo_owners]
      end
    end

    def repo_approvers_data
      if valid?
        mail_address_list(repo_ownership_repository.approvers_of(repo))
      else
        params[:repo_approvers]
      end
    end

    private

    def mail_address_list(emails)
      RepoAdmin.to_mail_address_list(emails).format.gsub(', ', "\n")
    end

    def repo_ownership_repository
      @repo_ownership_repository ||= Repositories::RepoOwnershipRepository.new
    end

    def owners_address_list
      @owners_address_list ||= parse_emails(repo_owners)
    end

    def approvers_address_list
      @approvers_address_list ||= parse_emails(repo_approvers)
    end

    def parse_emails(raw_emails)
      address_list = raw_emails.split(/\n|,/).map(&:strip).select(&:present?).join(', ')

      MailAddressList.new(address_list)
    end

    def validate_repo_owners
      return if owners_address_list.valid?

      errors.add(:repo_owners, 'is invalid')
    end

    def validate_repo_approvers
      return if approvers_address_list.valid?

      errors.add(:repo_owners, 'is invalid')
    end
  end
end
