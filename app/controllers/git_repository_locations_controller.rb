class GitRepositoryLocationsController < ApplicationController
  def index
    @git_repository_locations = GitRepositoryLocation.all.order(:name)
    @token_types = Forms::RepositoryLocationsForm.default_token_types
  end

  def create
    @token_types = Forms::RepositoryLocationsForm.default_token_types

    AddRepositoryLocation.run(git_repo_location_params).match do
      success do |repo_name|
        flash[:success] = get_success_msg(repo_name)

        redirect_to :git_repository_locations
      end

      failure do |message|
        @git_repository_locations = GitRepositoryLocation.all.order(:name)
        flash.now[:error] = message.errors if message
        render :index
      end
    end
  end

  private

  def get_success_msg(repo_name)
    msg = "Successfuly added #{repo_name} repository."
    msg.concat(' Selected tokens were generated'\
      'and can be found on Tokens page.') unless params[:token_types].blank?
    msg
  end

  def git_repo_location_params
    permitted = params.require(:repository_locations_form).permit(:uri)
    permitted[:token_types] = params[:token_types] if params[:token_types].present?
    permitted
  end
end
