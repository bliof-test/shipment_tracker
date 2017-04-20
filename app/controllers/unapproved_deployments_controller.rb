# frozen_string_literal: true
class UnapprovedDeploymentsController < ApplicationController
  before_action :update_region_cookies, only: [:show]

  def show
    update_region_cookies
    fetch_unapproved_deploys
    fetch_release_exceptions

    @app_name = app_name
    @github_repo_url = GitRepositoryLocation.github_url_for_app(app_name)
  end

  private

  def fetch_unapproved_deploys
    @unapproved_deploys = deploy_repository.unapproved_production_deploys_for(app_name: app_name, region: region)
  end

  def fetch_release_exceptions
    @release_exceptions = release_exception_repository.release_exception_for_application(app_name: app_name)
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
