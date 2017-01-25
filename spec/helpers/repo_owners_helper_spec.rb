# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RepoOwnersHelper do
  describe '#format_owner_emails' do
    it 'works with 1 repo owner' do
      repo_owner = RepoOwner.new name: 'John', email: 'test@test.com'

      expect(helper.format_owner_emails(repo_owner))
        .to eq('<span class="text-nowrap">John &lt;test@test.com&gt;</span>')
    end

    it 'works with array of owners' do
      repo_owner = RepoOwner.new name: 'John', email: 'test@test.com'
      repo_owner2 = RepoOwner.new email: 'test2@test.com'

      expect(helper.format_owner_emails([repo_owner, repo_owner2])).to eq(
        [
          '<span class="text-nowrap">John &lt;test@test.com&gt;</span>',
          '<span class="text-nowrap">test2@test.com</span>',
        ].join(', '),
      )
    end

    it 'returns an empty string when nothing is provided' do
      expect(helper.format_owner_emails).to eq('')
      expect(helper.format_owner_emails([])).to eq('')
    end
  end
end
