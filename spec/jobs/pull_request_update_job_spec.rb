require 'rails_helper'

RSpec.describe PullRequestUpdateJob do
  describe '#perform' do
    it 'passes its parameters to PullRequestStatus#update' do
      pr_status = instance_double(PullRequestStatus)
      params = { full_repo_name: 'owner/repo', sha: 'abc123' }

      allow(PullRequestStatus).to receive(:new).and_return(pr_status)
      expect(pr_status).to receive(:update).with(params)

      PullRequestUpdateJob.perform_now(params)
    end
  end
end
