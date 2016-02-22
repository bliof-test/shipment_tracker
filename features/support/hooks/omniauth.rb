Before do
  OmniAuth.config.test_mode = true
end

After do
  OmniAuth.config.test_mode = false
end

Before('@logged_in') do
  OmniAuth.config.mock_auth[:auth0] = OmniAuth::AuthHash.new(
    provider: 'auth0',
    uid: '123545',
    info: {
      first_name: 'John',
      email: 'john.doe@example.com',
    },
  )
  page.visit '/auth/auth0/callback'
  OmniAuth.config.mock_auth[:auth0] = nil
end
