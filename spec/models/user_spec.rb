# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User do
  def create_user(data = {})
    User.new(data)
  end

  describe '#logged_in?' do
    it 'is true if the user has an email' do
      expect(create_user(email: 'test@example.com')).to be_logged_in
    end

    it 'is not logged in if the user does not have an email' do
      expect(create_user).not_to be_logged_in
    end
  end

  describe '.as_repo_admin' do
    it 'will return a repo owner that has the same email if such exists' do
      repo_owner = FactoryGirl.create(:repo_admin, email: 'test@example.com')
      user = create_user(first_name: 'Test', email: 'test@example.com')

      expect(user.as_repo_admin).to eq(repo_owner)
    end

    it 'will return a new repo owner when there is none in the database' do
      user = create_user(first_name: 'Test', email: 'test@example.com')

      expect(user.as_repo_admin.name).to eq('Test')
      expect(user.as_repo_admin.email).to eq('test@example.com')
      expect(user.as_repo_admin).to_not be_persisted
    end
  end

  describe '#owner_of?' do
    it 'is true when the related repo owner has access to the repo' do
      repo_owner = FactoryGirl.build(:repo_admin, email: 'test@example.com')
      user = create_user(first_name: 'Test', email: 'test@example.com')

      allow(RepoAdmin).to receive(:find_by).with(email: 'test@example.com').and_return(repo_owner)

      repo = instance_double(GitRepositoryLocation)

      expect(repo_owner).to receive(:owner_of?).with(repo).and_return(true)
      expect(user.owner_of?(repo)).to be true
    end

    it "is false when the related repo owner doesn't have access to the repo" do
      repo_owner = FactoryGirl.build(:repo_admin, email: 'test@example.com')
      user = create_user(first_name: 'Test', email: 'test@example.com')

      allow(RepoAdmin).to receive(:find_by).with(email: 'test@example.com').and_return(repo_owner)

      repo = instance_double(GitRepositoryLocation)

      expect(repo_owner).to receive(:owner_of?).with(repo).and_return(false)
      expect(user.owner_of?(repo)).to be false
    end

    it 'is false when there is no related repo owner' do
      user = create_user(first_name: 'Test', email: 'different@example.com')

      repo = FactoryGirl.build(:git_repository_location)

      expect(user.owner_of?(repo)).to be false
    end
  end
end
