Given 'I am logged in as "$email"' do |email|
  OmniAuth.config.mock_auth[:auth0] = OmniAuth::AuthHash.new(
    provider: 'auth0',
    uid: '123545',
    info: {
      first_name: email.split('@').first,
      email: email,
    },
  )
  page.visit '/auth/auth0/callback'
  OmniAuth.config.mock_auth[:auth0] = nil
end
