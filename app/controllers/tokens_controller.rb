class TokensController < ApplicationController
  def index
    @token = Token.new
    @tokens = Token.order('LOWER(name)')
    @sources = Token.sources
  end

  def create
    Token.create(token_params)

    redirect_to tokens_path
  end

  def update
    Token.update(params[:id].to_i, params[:name] => params[:value])
    head :ok
  end

  def destroy
    Token.revoke(params[:id].to_i)

    redirect_to tokens_path
  end

  private

  def token_params
    params.require(:token).permit(:source, :name)
  end
end
