require 'spec_helper'
require 'git_cli'

RSpec.describe GitCLI do
  describe '.repo_accessible?' do
    let(:uri) { 'my_repo_uri' }

    it 'calls system with correct command' do
      expect(Kernel).to receive(:system).with("git ls-remote --heads #{uri} HEAD &>/dev/null")
      GitCLI.repo_accessible?(uri)
    end
  end
end
