# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RepoOwner do
  describe '.to_mail_address_list' do
    it 'will return a MailAddressList with the emails of the repo owners' do
      mail_list = RepoOwner.to_mail_address_list([
        FactoryGirl.build(:repo_owner, name: 'John', email: 'john@test.com'),
        FactoryGirl.build(:repo_owner, name: nil, email: 'ivan@test.com'),
      ])

      expect(mail_list).to be_kind_of(MailAddressList)
      expect(mail_list.format).to eq('John <john@test.com>, ivan@test.com')
    end
  end

  describe 'validations' do
    it 'is invalid when there is already a project owner with that email' do
      FactoryGirl.create(:repo_owner, email: 'test@duplication.com')
      repo_owner = FactoryGirl.build(:repo_owner, email: 'test@duplication.com')

      repo_owner.valid?

      expect(repo_owner.errors[:email]).to be_present
    end

    it 'is invalid if there is no email' do
      repo_owner = FactoryGirl.build(:repo_owner, email: nil)

      repo_owner.valid?

      expect(repo_owner.errors[:email]).to be_present
    end

    it 'is invalid if the email is bad' do
      repo_owner = FactoryGirl.build(:repo_owner, email: 'ninja')

      repo_owner.valid?

      expect(repo_owner.errors[:email]).to be_present
    end
  end

  describe '#owner_of?' do
    it 'is true when there is an active ownership between the repo and the owner' do
      repo_owner = FactoryGirl.build(:repo_owner)
      repo = double('Repo')

      expect_any_instance_of(Repositories::RepoOwnershipRepository)
        .to receive(:owners_of).with(repo).and_return([repo_owner])

      expect(repo_owner.owner_of?(repo)).to eq(true)
    end

    it "is false when there isn't an active ownership" do
      repo_owner = FactoryGirl.build(:repo_owner)
      repo = double('Repo')

      expect_any_instance_of(Repositories::RepoOwnershipRepository)
        .to receive(:owners_of).with(repo).and_return([])

      expect(repo_owner.owner_of?(repo)).to eq(false)
    end
  end
end
