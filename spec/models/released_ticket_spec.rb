# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReleasedTicket do
  def build_deploy_hash(app, time, version)
    {
      'app' => app,
      'deployed_at' => time,
      'version' => version,
    }
  end

  describe '#merges' do
    let(:released_ticket) { build(:released_ticket, deploys: deploys) }
    let(:merges) { released_ticket.merges }

    let(:repository_loader) { instance_double(GitRepositoryLoader) }
    let(:repository) { instance_double(GitRepository) }

    before do
      allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(repository_loader)
      allow(repository_loader).to receive(:load).and_return(repository)
    end

    context 'when merged commits have never been deployed' do
      let(:sha) { '63c504b1cc3ccd19a079e4ea2477809ff503a7af' }
      let(:commit) { build(:git_commit, id: sha, time: 1.minute.ago) }

      let(:deploy_time) { non_merge_commit.time + 1.day }
      let(:deploys) { [] }

      before do
        build(:merge, sha: commit.id, deploys: deploys, merged_at: commit.time)
      end

      it 'returns and empty array' do
        expect(repository).not_to receive(:commit_for_version)

        expect(merges).to be_empty
      end
    end

    context 'when merged commits have been deployed once or more' do
      let(:sha_1) { '63c504b1cc3ccd19a079e4ea2477809ff503a7af' }
      let(:sha_2) { 'da4bd0fd7ac7efce1c3f003645406911cc1d7f74' }

      let(:commits) do
        [merge_commit_1, merge_commit_2]
      end

      let(:merge_commit_1) { build(:git_commit, id: sha_1, time: 1.minute.ago) }
      let(:merge_commit_2) { build(:git_commit, id: sha_2, time: 2.minutes.ago) }

      let(:deploy_time_1) { merge_commit_1.time + 1.day }
      let(:deploy_time_2) { merge_commit_1.time + 2.days }
      let(:deploy_time_3) { merge_commit_2.time + 3.days }

      let(:deploy_hash_1) do
        [
          ['test_app_1', deploy_time_1, sha_1],
          ['test_app_1', deploy_time_2, sha_1],
        ].map { |app, time, version| build_deploy_hash(app, time, version) }
      end
      let(:deploy_hash_2) do
        [
          ['test_app_2', deploy_time_3, sha_2],
        ].map { |app, time, version| build_deploy_hash(app, time, version) }
      end

      let(:deploys) { deploy_hash_1 + deploy_hash_2 }

      before do
        build(:merge, sha: merge_commit_1.id, deploys: deploy_hash_1, merged_at: merge_commit_1.time)
        build(:merge, sha: merge_commit_2.id, deploys: deploy_hash_2, merged_at: merge_commit_2.time)
      end

      it 'returns the merges with the related deploys' do
        expect(repository).to receive(:commit_for_version).with(sha_1).and_return(merge_commit_1)
        expect(repository).to receive(:commit_for_version).with(sha_2).and_return(merge_commit_2)

        expect(merges).to all(be_a(Merge))
        expect(merges.map(&:sha)).to eq(commits.map(&:id))
        expect(merges.map(&:deploys).flatten).to eq(deploys)
      end
    end
  end
end
