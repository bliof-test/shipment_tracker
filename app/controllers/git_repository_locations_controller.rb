class GitRepositoryLocationsController < ApplicationController
  def index
    @git_repository_locations = GitRepositoryLocation.all.order(:name)
    @token_types = Forms::RepositoryLocationsForm.default_token_types
  end

  def create
    @token_types = Forms::RepositoryLocationsForm.default_token_types

    AddRepositoryLocation.run(git_repo_location_params).match do
      success do |repo_name|
        flash[:success] = %Q[#{ActionController::Base.helpers.link_to('Tokens', tokens_path)}].html_safe
        # get_success_msg(
        #   repo_name,
        #   url_for(action: 'index', controller: 'tokens', only_path: false, protocol: 'https'),
        # ).html_safe

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

  def get_success_msg(repo_name, tokens_link)
    msg = "Successfuly added #{repo_name} repository."
    msg.concat(" Selected tokens were generated" \
      "and can be found on <a href='#{tokens_link}'>Tokens</a> page.") unless params[:token_types].blank?
    msg
  end

  def git_repo_location_params
    permitted = params.require(:repository_locations_form).permit(:uri)
    permitted[:token_types] = params[:token_types] if params[:token_types].present?
    permitted
  end
end
