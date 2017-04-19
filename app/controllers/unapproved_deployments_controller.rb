# frozen_string_literal: true
class UnapprovedDeploymentsController < ApplicationController
  def show
    update_cookies
    redirect_to unapproved_deployment_path(app_name, region: region) unless params[:region]
    fetch_unapproved_deploys
    fetch_release_exceptions

    @app_name = app_name
    @github_repo_url = GitRepositoryLocation.github_url_for_app(app_name)
  rescue GitRepositoryLoader::NotFound
    render text: 'Repository not found', status: :not_found
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

  def update_cookies
    cookies.permanent[:deploy_region] ||= Rails.configuration.default_deploy_region
    cookies.permanent[:deploy_region] = params[:region] if params[:region]
  end

  def git_repository
    git_repository_loader.load(app_name)
  end

  def force_html_format
    request.format = 'html'
  end
end
