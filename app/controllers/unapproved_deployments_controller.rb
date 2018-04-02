# frozen_string_literal: true

class UnapprovedDeploymentsController < ApplicationController
  before_action :force_html_format, only: :show
  before_action :update_region_cookies, only: :show

  def show
    update_region_cookies
    fetch_unapproved_deploys
    fetch_release_exceptions

    @app_name = app_name
    @github_repo_url = GitRepositoryLocation.github_url_for_app(app_name)
  end

  private

  def start_date
    return @start_date if @start_date.present?

    default_start_date = 1.month.ago.to_date
    @start_date = params[:start_date].present? ? Date.strptime(params[:start_date], '%Y-%m-%d') : default_start_date
  end

  def end_date
    return @end_date if @end_date.present?

    default_end_date = Time.zone.today
    @end_date = params[:end_date].present? ? Date.strptime(params[:end_date], '%Y-%m-%d') : default_end_date
  end

  def fetch_unapproved_deploys
    @unapproved_deploys = deploy_repository.unapproved_production_deploys_for(
      app_name: app_name,
      region: region,
      from_date: start_date,
      to_date: end_date,
    )
  end

  def fetch_release_exceptions
    @release_exceptions = release_exception_repository.release_exception_for_application(
      app_name: app_name,
      from_date: start_date,
      to_date: end_date,
    )
  end

  def deploy_repository
    @deploy_repository ||= Repositories::DeployRepository.new
  end

  def release_exception_repository
    @release_exception_repository ||= Repositories::ReleaseExceptionRepository.new
  end

  def app_name
    if request.path_parameters[:format]
      "#{params[:id]}.#{request.path_parameters[:format]}"
    else
      params[:id]
    end
  end

  def region
    @region = cookies[:deploy_region]
  end

  def git_repository
    git_repository_loader.load(app_name)
  end
end
