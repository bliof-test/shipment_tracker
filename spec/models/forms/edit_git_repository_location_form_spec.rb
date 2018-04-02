# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forms::EditGitRepositoryLocationForm do
  def form_for(form_data = {}, options = {})
    repo = options.fetch(:repo, FactoryBot.create(:git_repository_location))
    current_user = options.fetch('current_user', double('User', email: 'test@test.com'))

    described_class.new(repo: repo, params: form_data, current_user: current_user)
  end

  describe 'validation' do
    describe 'for repo_owners' do
      it 'could be blank' do
        expect(form_for(repo_owners: '')).to be_valid
        expect(form_for(repo_owners: nil)).to be_valid
      end

      describe 'a single repo owner' do
        it 'expects an email or a name with email' do
          expect(form_for(repo_owners: 'test@example.com')).to be_valid
          expect(form_for(repo_owners: 'Test Example<test@example.com>')).to be_valid
        end

        it 'will fail if the provided value is neither an email nor a name with email' do
          ['test', 'test test@example.com'].each do |example|
            form = form_for(repo_owners: example)

            expect(form).not_to be_valid
            expect(form.errors[:repo_owners]).to be_present
          end
        end
      end

      it 'works with a list of repo owners separated by a new line or comma' do
        [
          "test@example.com\nTest Example <test@example.com>",
          "\n\nTest <test@example.com>  \n\n\nTest Example <test2@example.com>  \n\n\n",
          "Test <test@example.com>, Test Example <test2@example.com>\nTest Example <test3@example.com>",
        ].each do |data|
          expect(form_for(repo_owners: data)).to be_valid
        end
      end
    end

    describe 'for audit options' do
      it 'could be blank' do
        expect(form_for(audit_options: [])).to be_valid
        expect(form_for(audit_options: nil)).to be_valid
      end

      it 'could contain only certain checks' do
        expect(form_for(audit_options: %w[isae_3402])).to be_valid
        expect(form_for(audit_options: %w[invalid_check])).not_to be_valid
      end
    end
  end

  describe '#call' do
    let(:form) {
      form_for(
        {
          repo_owners: "test@example.com, test3@example.com \n\n\nTest Example <test2@example.com>  \n\n\n",
          audit_options: %w[isae_3402],
        },
        repo: FactoryBot.create(:git_repository_location, name: 'my-app'),
        current_user: double('User', email: 'test@test.com'),
      )
    }

    it 'will generate a repo ownership event' do
      repo = FactoryBot.create(:git_repository_location, name: 'my-app')
      current_user = double('User', email: 'test@test.com')
      owner_data = "test@example.com, test3@example.com \n\n\nTest Example <test2@example.com>  \n\n\n"
      approver_data = "test4@example.com, test5@example.com \n\n\nTest Example <test6@example.com>  \n\n\n"

      form = form_for(
        { repo_owners: owner_data, repo_approvers: approver_data },
        repo: repo,
        current_user: current_user,
      )

      expect(Events::RepoOwnershipEvent).to(
        receive(:create!).with(
          details: {
            app_name: 'my-app',
            repo_owners: 'test@example.com, test3@example.com, Test Example <test2@example.com>',
            repo_approvers: 'test4@example.com, test5@example.com, Test Example <test6@example.com>',
            email: 'test@test.com',
          },
        ),
      )

      form.call
    end

    it 'will generate a git repository location event' do
      expect(Events::GitRepositoryLocationEvent).to(
        receive(:create!).with(
          details: {
            app_name: 'my-app',
            audit_options: %w[isae_3402],
          },
        ),
      )

      form.call
    end
  end
end
