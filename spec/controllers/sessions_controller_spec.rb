require 'rails_helper'

RSpec.describe SessionsController do
  describe '#get :auth0_success_callback' do
    before do
      request.env['omniauth.auth'] = omniauth_response
    end

    let(:omniauth_response) do
      {
        'info' => {
          'first_name' => 'Jim',
          'email' => 'jim@example.com',
        },
      }
    end

    it 'redirects to root' do
      expect(get :auth0_success_callback).to redirect_to(root_path)
    end

    context 'when redirect_path is set in sesssion' do
      let(:redirect_path) { '/any-path' }

      before do
        session[:redirect_path] = redirect_path
      end

      it 'redirects to redirect_path' do
        expect(get :auth0_success_callback).to redirect_to(redirect_path)
      end
    end

    it 'stores user in session' do
      get :auth0_success_callback

      expect(session[:current_user]['first_name']).to eq('Jim')
      expect(session[:current_user]['email']).to eq('jim@example.com')
    end

    context 'user first name not returned' do
      let(:omniauth_response) do
        {
          'info' => {
            'email' => 'jim@example.com',
          },
        }
      end

      it 'displays flash notice' do
        get :auth0_success_callback

        expect(flash[:info]).to eq('Hello jim@example.com!')
      end
    end

    context 'user first name returned' do
      it 'displays flash notice' do
        get :auth0_success_callback

        expect(flash[:info]).to eq('Hello Jim!')
      end
    end
  end

  describe '#auth0_failure_callback' do
    it 'says sorry' do
      get :auth0_failure_callback

      expect(response.body).to eq('Sorry - you are not authorized to use this application.')
      expect(response.status).to eq(401)
    end
  end

  describe '#destroy' do
    it 'empties session' do
      session[:current_user] = 'Jim'
      delete :destroy
      expect(session[:current_user]).to be_nil
    end

    it 'redirects to Auth0 logout' do
      stub_const('ENV', 'AUTH0_DOMAIN' => 'test.auth.com')
      expect(delete :destroy).to redirect_to('https://test.auth.com/logout')
    end
  end
end
