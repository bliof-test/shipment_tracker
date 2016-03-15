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
end
