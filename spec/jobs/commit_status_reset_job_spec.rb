# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommitStatusResetJob do
  describe '#perform' do
    it 'passes its parameters to CommitStatus#reset' do
      pr_status = instance_double(CommitStatus)
      params = { full_repo_name: 'owner/repo', sha: 'abc123' }

      allow(CommitStatus).to receive(:new).with(params).and_return(pr_status)
      expect(pr_status).to receive(:reset)

      described_class.perform_now(params)
    end
  end
end
