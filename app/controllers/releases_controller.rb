# frozen_string_literal: true
class ReleasesController < ApplicationController
  before_action :force_html_format, only: :show

  def index
    @app_names = GitRepositoryLocation.app_names
  end

  def show
    update_cookies
    redirect_to release_path(app_name, region: region) unless params[:region]
    projection = build_projection
    @pending_releases = projection.pending_releases
    @deployed_releases = projection.deployed_releases
    @app_name = app_name
    @github_repo_url = GitRepositoryLocation.github_url_for_app(app_name)
  rescue GitRepositoryLoader::NotFound
    render text: 'Repository not found', status: :not_found
  end

  private

  def build_projection
    Queries::ReleasesQuery.new(
      per_page: 50,
      region: region,
      git_repo: git_repository,
      app_name: app_name)
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
end
