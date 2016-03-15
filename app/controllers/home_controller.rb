class HomeController < ApplicationController
  skip_before_action :require_authentication

  def index
    @query = params[:q]
    @results = [
      { 'Jira Key' => 'ENG-2', 'Summary' => 'Make another task',
        'Description' => "As a User\r\n implement another task" },
      { 'Jira Key' => 'ENG-2', 'Summary' => 'Make another story',
        'Description' => "As a User\r\n implement another story" },
    ]
    render 'dashboard' if params[:preview] == 'true'
  end
end
