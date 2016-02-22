Before('@disable_repo_verification') do
  allow_any_instance_of(OctokitClient).to receive(:repo_accessible?).and_return(true)
end
