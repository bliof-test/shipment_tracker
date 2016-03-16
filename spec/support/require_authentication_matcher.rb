require 'rspec/expectations'

RSpec::Matchers.define :require_authentication_on do |verb, action, *args|
  match do
    response = process(action, verb.to_s.upcase, *args)
    expect(response).to redirect_to(expected_login_path)
  end

  failure_message do
    <<-EOS.strip_heredoc
    Expected #{verb} on #{action} to require authentication:
      - Redirect to #{expected_login_path}
    EOS
  end

  description do
    "require authentication on #{verb.upcase} ##{action} #{args.map(&:inspect).join(', ')}"
  end

  def expected_login_path
    '/auth/auth0'
  end
end
