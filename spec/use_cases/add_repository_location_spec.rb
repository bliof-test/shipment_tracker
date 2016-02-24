require 'rails_helper'
require 'add_repository_location'
require 'forms/repository_locations_form'

RSpec.describe AddRepositoryLocation do
  let(:form) { double() }
  let(:git_repo_location) { double() }

  before do
    allow(form).to receive(:valid?).and_return(true)
    allow(git_repo_location).to receive(:save).and_return(true)
  end

  context 'when valid URI and a token selected' do
    it 'runs successfully' do
      result = AddRepositoryLocation.run(validation_form: form, uri: 'git@github.com/owner/repo.git')
      expect(result).to be_a_success
    end

    it 'adds repository' do
      expect(GitRepositoryLocation).to receive(:new).and_return(git_repo_location)
      AddRepositoryLocation.run(validation_form: form, uri: 'git@github.com/owner/repo.git')
    end

    xit 'generates tokens' do
    end
  end

  context 'when invalid URI' do

    it 'fails validation' do
      allow(form).to receive(:valid?).and_return(false)
      result = AddRepositoryLocation.run(validation_form: form, uri: 'owner/repo.git')
      expect(result).to fail_with(:invalid_uri)
    end
  end
end
