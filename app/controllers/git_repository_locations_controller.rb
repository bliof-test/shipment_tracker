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

  private

  def success_msg(repo_name)
    render_to_string partial: 'partials/add_repo_success_msg', locals: { repo_name: repo_name }
  end

  def git_repo_location_params
    permitted = params.require(:repository_locations_form).permit(:uri)
    permitted[:token_types] = params[:token_types] if params[:token_types].present?
    permitted
  end
end
