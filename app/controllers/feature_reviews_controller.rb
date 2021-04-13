# frozen_string_literal: true

class FeatureReviewsController < ApplicationController
  before_action :sanitize_jira_key_param, only: %i[link_ticket unlink_ticket]

  def new
    @app_names = GitRepositoryLocation.app_names
    @feature_review_form = feature_review_form
  end

  def create
    @feature_review_form = feature_review_form
    if @feature_review_form.valid?
      redirect_to @feature_review_form.path
    else
      @app_names = GitRepositoryLocation.app_names
      render :new
    end
  end

  def show
    @return_to = request.original_fullpath

    feature_review = factory.create_from_url_string(request.original_url)
    @feature_review_with_statuses = Queries::FeatureReviewQuery.new(feature_review, at: time)
                                                               .feature_review_with_statuses
  end

  def link_ticket
    LinkTicket.run(ticket_linking_options).match do
      success do |success_message|
        flash[:success] = success_message
      end

      failure do |error|
        flash[:error] = error.message
      end
    end

    redirect_to redirect_path
  end

  def unlink_ticket
    args = ticket_linking_options.merge(apps: params.fetch(:apps))
    UnlinkTicket.run(args).match do
      success do |success_message|
        flash[:success] = success_message
      end

      failure do |error|
        flash[:error] = error.message
      end
    end
    redirect_to feature_reviews_path(apps: params[:apps])
  end

  private

  def ticket_linking_options
    { jira_key: params[:jira_key], feature_review_path: redirect_path, root_url: root_url }
  end

  def time
    # Add fraction of a second to work around microsecond time difference.
    # The "time" query value in the Feature Review URL has no microseconds (i.e. 0 usec),
    # whereas the times records are persisted to the DB have higher precision which includes microseconds.
    params.fetch(:time, nil).try { |t| Time.zone.parse(t).change(usec: 999_999.999) }
  end

  def factory
    Factories::FeatureReviewFactory.new
  end

  def feature_review_form
    form_input = params.fetch(:forms_feature_review_form, ActionController::Parameters.new).permit!.to_h
    Forms::FeatureReviewForm.new(
      apps: form_input[:apps],
      git_repository_loader: git_repository_loader,
    )
  end

  def git_repository_for(app_name)
    git_repository_loader.load(app_name)
  end

  def redirect_path
    @redirect_path ||= normalize_feature_review_path(path_from_url(params[:return_to]))
  end

  def normalize_feature_review_path(path)
    factory.create_from_url_string(path).path
  end

  def sanitize_jira_key_param
    params[:jira_key] = params[:jira_key].upcase.strip unless params[:jira_key].nil?
  end
end
