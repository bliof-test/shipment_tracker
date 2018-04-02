# frozen_string_literal: true

module Pages
  def git_repository_location_page
    Pages::GitRepositoryLocationPage.new(
      page: page,
      url_helpers: Rails.application.routes.url_helpers,
    )
  end

  def edit_git_repository_location_page
    Pages::EditGitRepositoryLocationPage.new(
      page: page,
      url_helpers: Rails.application.routes.url_helpers,
    )
  end

  def prepare_feature_review_page
    Pages::PrepareFeatureReviewPage.new(
      page: page,
      url_helpers: Rails.application.routes.url_helpers,
    )
  end

  def feature_review_page
    Pages::FeatureReviewPage.new(
      page: page,
      url_helpers: Rails.application.routes.url_helpers,
    )
  end

  def dashboard_page
    Pages::DashboardPage.new(
      page: page,
      url_helpers: Rails.application.routes.url_helpers,
    )
  end

  def releases_page
    Pages::ReleasesPage.new(
      page: page,
      url_helpers: Rails.application.routes.url_helpers,
    )
  end

  def tokens_page
    Pages::TokensPage.new(
      page: page,
      url_helpers: Rails.application.routes.url_helpers,
    )
  end

  def alert_message
    Pages::AlertMessage.new(
      page: page,
      url_helpers: Rails.application.routes.url_helpers,
    )
  end
end

World(Pages)
