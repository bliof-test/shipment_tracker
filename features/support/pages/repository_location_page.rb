# frozen_string_literal: true
module Pages
  class GitRepositoryLocationPage
    def initialize(page:, url_helpers:)
      @page        = page
      @url_helpers = url_helpers
    end

    def visit
      page.visit url_helpers.git_repository_locations_path
    end

    def fill_in(uri:)
      page.fill_in 'Git URI', with: uri
      page.click_link_or_button('Add Git Repository')
      self
    end

    def git_repository_locations
      Sections::TableSection.new(page.find('table.git_repository_locations')).items
    end

    private

    attr_reader :page, :url_helpers
  end

  class EditGitRepositoryLocationPage
    def initialize(page:, url_helpers:)
      @page        = page
      @url_helpers = url_helpers
    end

    def visit(application)
      page.visit url_helpers.edit_git_repository_location_path(application)
    end

    def fill_in_repo_owners(repo_owners:)
      page.fill_in 'Repo Owners', with: repo_owners
    end

    def fill_in_repo_approvers(repo_approvers:)
      page.fill_in 'Repo Approvers', with: repo_approvers
    end

    def click(button)
      page.click_link_or_button(button)
    end

    private

    attr_reader :page, :url_helpers
  end
end
