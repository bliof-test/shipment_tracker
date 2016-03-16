# frozen_string_literal: true
require 'clients/github'

Before('@disable_repo_verification') do
  allow_any_instance_of(GithubClient).to receive(:repo_accessible?).and_return(true)
end
