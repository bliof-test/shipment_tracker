require 'rails_helper'

RSpec.describe GitRepositoryFetchJob do
  describe '#perform' do
    before do
      allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(loader)
    end

    let(:loader) { instance_double(GitRepositoryLoader) }

    it 'consider_all_requests_local GitRepositoryLoader#load_and_update' do
      params = { name: 'frontend' }

      expect(loader).to receive(:load_and_update).with('frontend')

      GitRepositoryFetchJob.perform_now(params)
    end

    it 'expects the name attribute to exist' do
      params = {}

      expect { GitRepositoryFetchJob.perform_now(params) }.to raise_error(KeyError)
    end
  end
end
