# frozen_string_literal: true
class GitRepositoryLocationsController < ApplicationController
  def index
    @git_repository_locations = GitRepositoryLocation.all.order(:name)
    @token_types = Forms::RepositoryLocationsForm.default_token_types
  end

  def create
    @token_types = Forms::RepositoryLocationsForm.default_token_types

    AddRepositoryLocation.run(git_repo_location_params).match do
      success do |repo_name|
        flash[:success] = success_msg(repo_name)
        redirect_to :git_repository_locations
      end

      failure do |error|
        @git_repository_locations = GitRepositoryLocation.all.order(:name)
        flash.now[:error] = error.message
        render :index
      end
    end
  end

  def edit
    load_edit_env

    @form = form_for(@git_repository_location)
  end

  def update
    load_edit_env

    edit_params = params.require(:forms_edit_git_repository_location_form)
                        .permit(:repo_owners, :repo_approvers, audit_options: [])
    @form = form_for(@git_repository_location, edit_params)

    if @form.call
      flash[:success] = "Repository #{@repository_name} successfully updated!"
      redirect_to action: :index
    else
      render 'edit'
    end
  end

  private

  def form_for(repo, params = {})
    Forms::EditGitRepositoryLocationForm.new(repo: repo, current_user: current_user, params: params)
  end

  def load_edit_env
    @git_repository_location = GitRepositoryLocation.find(params[:id])
    @repository_name = @git_repository_location.name
    @repository_uri = @git_repository_location.uri
  end

  def success_msg(repo_name)
    render_to_string partial: 'partials/add_repo_success_msg', locals: { repo_name: repo_name }
  end

  def git_repo_location_params
    permitted = params.require(:repository_locations_form).permit(:uri)
    permitted[:uri] = permitted[:uri].strip
    permitted[:token_types] = params[:token_types] if params[:token_types].present?
    permitted
  end
end
