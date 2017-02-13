# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CommitStatusUpdateJob do
  describe '#perform' do
    it 'passes its parameters to CommitStatus#update' do
      pr_status = instance_double(CommitStatus)
      params = { full_repo_name: 'owner/repo', sha: 'abc123' }

      allow(CommitStatus).to receive(:new).with(params).and_return(pr_status)
      expect(pr_status).to receive(:update)

      CommitStatusUpdateJob.perform_now(params)
    end
  end
end
