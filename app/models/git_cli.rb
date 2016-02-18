class GitCLI
  def self.repo_accessible?(uri)
    Kernel.system("git ls-remote --heads #{uri} HEAD &>/dev/null")
  end
end
