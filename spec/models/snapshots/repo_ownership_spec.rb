# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Snapshots::RepoOwnership do
  describe '.for' do
    it 'returns the snapshot for specific git repository' do
      repo = double('Repo', name: 'test-repo')
      snapshot = create(:repo_ownership_snapshot, app_name: 'test-repo')

      expect(described_class.for(repo)).to eq(snapshot)
    end

    context 'when there is no snapshot' do
      it 'it returns a non-persisted one with the correct app_name' do
        repo = double('Repo', name: 'test-repo')

        snapshot = described_class.for(repo)

        expect(snapshot.app_name).to eq('test-repo')
        expect(snapshot).to_not be_persisted
      end
    end
  end

  describe '#owner_emails' do
    it 'returns a mail address list from the snapshotted repo owner emails' do
      snapshot = build(:repo_ownership_snapshot, repo_owners: 'Test <test@example.com>, foo@bar.baz')

      expect(snapshot.owner_emails).to be_kind_of(MailAddressList)
      expect(snapshot.owner_emails.format).to eq('Test <test@example.com>, foo@bar.baz')
    end
  end
end
