# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RepoAdmin do
  describe '.to_mail_address_list' do
    it 'will return a MailAddressList with the emails of the repo owners' do
      mail_list = RepoAdmin.to_mail_address_list([
        FactoryBot.build(:repo_admin, name: 'John', email: 'john@test.com'),
        FactoryBot.build(:repo_admin, name: nil, email: 'ivan@test.com'),
      ])

      expect(mail_list).to be_kind_of(MailAddressList)
      expect(mail_list.format).to eq('John <john@test.com>, ivan@test.com')
    end
  end

  describe 'validations' do
    it 'is invalid when there is already a project owner with that email' do
      FactoryBot.create(:repo_admin, email: 'test@duplication.com')
      repo_owner = FactoryBot.build(:repo_admin, email: 'test@duplication.com')

      repo_owner.valid?

      expect(repo_owner.errors[:email]).to be_present
    end

    it 'is invalid if there is no email' do
      repo_owner = FactoryBot.build(:repo_admin, email: nil)

      repo_owner.valid?

      expect(repo_owner.errors[:email]).to be_present
    end

    it 'is invalid if the email is bad' do
      repo_owner = FactoryBot.build(:repo_admin, email: 'ninja')

      repo_owner.valid?

      expect(repo_owner.errors[:email]).to be_present
    end
  end

  describe '#owner_of?' do
    it 'is true when there is an active ownership between the repo and the owner' do
      repo_owner = FactoryBot.build(:repo_admin)
      repo = double('Repo')

      expect(repo).to receive(:owners).and_return([repo_owner])

      expect(repo_owner.owner_of?(repo)).to eq(true)
    end

    it "is false when there isn't an active ownership" do
      repo_owner = FactoryBot.build(:repo_admin)
      repo = double('Repo')

      expect(repo).to receive(:owners).and_return([])

      expect(repo_owner.owner_of?(repo)).to eq(false)
    end
  end
end
