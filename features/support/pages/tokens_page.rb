module Pages
  class TokensPage
    def initialize(page:, url_helpers:)
      @page        = page
      @url_helpers = url_helpers
    end

    def visit
      page.visit url_helpers.tokens_path
    end

    def generate_token_for(source, name)
      verify!
      page.select source, from: 'Source'
      page.fill_in 'Name', with: name
      page.click_on 'Create Token'
    end

    def tokens
      verify!
      Sections::TableSection.new(page.find('table.tokens')).items
    end

    def revoke_last_token
      verify!
      page.first('table.tokens .action-revoke').click
    end

    private

    def verify!
      fail "Expected to be on a Tokens page, but was on #{page.current_url}" unless on_page?
    end

    def on_page?
      page.current_url =~ Regexp.new(Regexp.escape(url_helpers.tokens_path))
    end

    attr_reader :page, :url_helpers
  end
end
