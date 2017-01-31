# frozen_string_literal: true
module FeatureReviewsHelper
  def table(headers: [], classes: nil, &block)
    haml_tag('table.table.table-striped', class: classes) do
      haml_tag('thead') do
        haml_tag('tr') do
          headers.each do |header|
            haml_tag('th', header)
          end
        end
      end
      haml_tag('tbody', &block)
    end
  end

  def panel_class(status)
    "panel-#{item_class(status)}"
  end

  def text_class(status)
    "text-#{item_class(status)}"
  end

  def icon_class(status)
    "icon-#{item_class(status)}"
  end

  def item_status_icon_class(status)
    "#{icon_class(status)} status #{text_class(status)}"
  end

  def item_class(status)
    case status
    when true, :success, :approved
      'success'
    when false, :failure, :not_approved, :requires_reapproval
      'danger'
    else
      'warning'
    end
  end

  def owner_of_any_repo?(user, feature_review)
    repos = GitRepositoryLocation.where(name: feature_review.app_names)
    repos.any? { |repo| user.owner_of?(repo) }
  end

  def to_link(url, options = {})
    link_to url, Addressable::URI.heuristic_parse(url).to_s, options
  end

  def feature_status(feature_review)
    status = "Feature Status: #{feature_review.authorisation_status.to_s.humanize}"
    status = "#{status} at #{feature_review.approved_at}" if feature_review.authorised?
    status
  end

  def jira_link(jira_key)
    link_to(
      jira_key,
      "#{ShipmentTracker::JIRA_FQDN}/browse/#{jira_key}",
      target: '_blank',
    )
  end

  def edit_url(app_versions, uat_url)
    new_feature_reviews_path(forms_feature_review_form: { apps: app_versions, uat_url: uat_url })
  end
end
