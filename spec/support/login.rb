module Support
  module Login
    module Controller
      def login_with_omniauth(
        uid: 'xyz',
        email: 'foo@bar.com',
        first_name: 'Alice'
      )
        request.env['omniauth.auth'] = {
          'uid' => uid,
          'info' => {
            'email' => email,
            'first_name' => first_name,
          },
        }
      end
    end

    module Request
      def login_with_omniauth(
        uid: 'xyz',
        email: 'foo@bar.com',
        first_name: 'Alice'
      )
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth[:auth0] = {
          'uid' => uid,
          'info' => {
            'email' => email,
            'first_name' => first_name,
          },
        }
        get Rails.configuration.login_callback_url
      ensure
        OmniAuth.config.test_mode = false
      end
    end
  end
end
