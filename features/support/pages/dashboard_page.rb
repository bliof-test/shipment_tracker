# frozen_string_literal: true
module Pages
  class DashboardPage
    def initialize(page:, url_helpers:)
      @page        = page
      @url_helpers = url_helpers
    end

    def search_for(query:, from: nil, to: nil)
      page.visit url_helpers.root_path
      page.fill_in('q', with: query)
      page.fill_in('from_date', with: from)
      page.fill_in('to_date', with: to)
      page.click_button('Search')
    end

    def results
      verify!
      Sections::ResultsSection.new(
        page.all('.result'),
      ).items
    end

    private

    def verify!
      fail "Expected to be on a Dashboard page, but was on #{page.current_url}" unless on_page?
    end

    def on_page?
      page.current_url =~ Regexp.new(Regexp.escape(url_helpers.root_path))
    end

    attr_reader :page, :url_helpers
  end
end
