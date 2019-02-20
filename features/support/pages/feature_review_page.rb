# frozen_string_literal: true

module Pages
  class FeatureReviewPage
    def initialize(page:, url_helpers:)
      @page        = page
      @url_helpers = url_helpers
    end

    def app_info
      verify!
      Sections::TableSection.new(
        page.find('.app-info table'),
      ).items.map { |row| { 'app_name' => row['App'], 'version' => row['Commit'] } }
    end

    def builds
      verify!
      Sections::TableSection.new(
        page.find('.builds table'),
        icon_translations: {
          'text-success' => 'success',
          'text-danger' => 'failed',
          'text-warning' => 'warning',
        },
      ).items
    end

    def panel_heading_status(panel_class)
      verify!
      page.find(".panel.#{panel_class}")[:class].match(/panel-(?<status>\w+)/)[:status]
    end

    def deploys
      verify!
      Sections::TableSection.new(
        page.find('.deploys table'),
        icon_translations: {
          'text-success' => 'yes',
          'text-danger' => 'no',
        },
      ).items
    end

    def create_submission(status:, comment:, type:)
      type_panel_matching = {
        'QA' => '.qa-submission',
        'Repo Owner' => '.release-exception',
      }

      verify!
      page.choose(status.capitalize)

      page.within(type_panel_matching[type]) do
        page.fill_in('Comment', with: comment)
        page.click_link_or_button('Submit')
      end
    end

    def link_a_jira_ticket(jira_key:)
      verify!
      page.fill_in('jira_key', with: jira_key)
      page.click_link_or_button('Link')
    end

    def unlink_a_jira_ticket(jira_key:)
      verify!
      page.find('tr', text: jira_key) { click_link_or_button('unlink') }
    end

    def qa_submission_panel
      verify!
      Sections::PanelListSection.new(
        page.find('.qa-submission.panel'),
        item_config: {
          'comment' => '.qa-comment',
          'email' => '.qa-email',
        },
      )
    end

    def release_exception_panel
      verify!
      Sections::PanelListSection.new(
        page.find('.release-exception.panel'),
        item_config: {
          'comment' => '.repo-owner-comment',
          'email' => '.repo-owner-email',
        },
      )
    end

    def tickets
      verify!
      Sections::TableSection.new(page.find('.feature-status table')).items.map { |row| row.except('Actions') }
    end

    def summary_panel
      verify!
      Sections::PanelListSection.new(
        page.find('.summary'),
        item_config: {
          'title' => '.title',
          'status' => '.status',
        },
      )
    end

    def feature_status
      verify!
      page.find('.feature-status.panel').find('.panel-heading').text
    end

    def time
      verify!
      page.find('.time').text
    end

    private

    attr_reader :page, :url_helpers

    def verify!
      fail "Expected to be on a Feature Review page, but was on #{page.current_url}" unless on_page?
    end

    def on_page?
      page.current_url =~ Regexp.new(Regexp.escape(url_helpers.feature_reviews_path + '?'))
    end
  end
end
