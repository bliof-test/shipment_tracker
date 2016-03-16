module Pages
  class AlertMessage
    def initialize(page:, url_helpers:)
      @page        = page
      @url_helpers = url_helpers
    end

    def text
      page.all(selector).map(&:text).join("\n")
    end

    private

    attr_reader :page, :url_helpers

    def selector
      '.alert'
    end
  end
end
