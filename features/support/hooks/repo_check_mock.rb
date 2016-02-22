Before('@disable_repo_verification') do
  allow(GitCLI).to receive(:repo_accessible?).and_return(true)
end
