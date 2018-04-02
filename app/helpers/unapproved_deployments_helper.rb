# frozen_string_literal: true

module UnapprovedDeploymentsHelper
  def tickets_for_versions(versions)
    Repositories::TicketRepository.new.tickets_for_versions(versions)
  end

  def feature_reviews_for_versions(app_name, versions)
    commits = versions.map { |version| GitCommit.new(id: version) }
    Queries::DecoratedFeatureReviewsQuery.new(app_name, commits).get
  end
end
