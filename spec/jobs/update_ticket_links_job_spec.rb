# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateTicketLinksJob do
  let(:org_name) { 'acme' }
  let(:repo_name) { 'awesome-app' }
  let(:full_repo_name) { "#{org_name}/#{repo_name}" }
  let(:before_sha) { '123456789' }
  let(:after_sha) { '987654321' }
  let(:ticket_key) { 'MOB-123' }
  let(:expected_url) { "https://localhost/feature_reviews?apps%5B#{repo_name}%5D=#{after_sha}" }

  describe '#perform' do
    let(:ticket_repository) { instance_double(Repositories::TicketRepository) }

    before :each do
      allow(Repositories::TicketRepository).to receive(:new).and_return(ticket_repository)
      allow(ticket_repository).to receive(:tickets_for_path).and_return([])
      allow(ticket_repository).to receive(:tickets_for_versions).and_return([])
    end

    context 'given a push for a newly created branch with a ticket key in the branch name' do
      let(:args) do
        {
          full_repo_name: full_repo_name,
          before_sha: '123456789',
          after_sha: '987654321',
          branch_created: true,
          branch_name: "#{ticket_key}-super-feature",
        }
      end

      it 'links the correct ticket key' do
        expected_comment = "[Feature ready for review|#{expected_url}]"
        expect(JiraClient).to receive(:post_comment).with(ticket_key, expected_comment)
        stub = stub_request(:post, "https://api.github.com/repos/#{full_repo_name}/statuses/#{after_sha}")
               .to_return(status: 200)
        subject.perform(args)
        remove_request_stub(stub)
      end
    end
  end

  describe '#extract_ticket_key_from_branch_name' do
    context 'given a branch name that contains a JIRA ticket key at the start' do
      it 'finds the ticket key' do
        extracted_key = subject.send(:extract_ticket_key_from_branch_name, "#{ticket_key}-some-feature")
        expect(extracted_key).to eq(ticket_key)
      end
    end

    context 'given a branch name that contains a JIRA ticket key in the middle' do
      it 'does not find a ticket key' do
        extracted_key = subject.send(:extract_ticket_key_from_branch_name, "some-#{ticket_key}-feature")
        expect(extracted_key).to eq(ticket_key)
      end
    end

    context 'given a branch name that contains a JIRA ticket key at the end' do
      it 'does not find a ticket key' do
        extracted_key = subject.send(:extract_ticket_key_from_branch_name, "some-feature-#{ticket_key}")
        expect(extracted_key).to eq(ticket_key)
      end
    end

    context 'given a branch name that has a lower case ticket key' do
      it 'does not find a ticket key' do
        extracted_key = subject.send(:extract_ticket_key_from_branch_name, ticket_key.downcase)

        # Case check allows devs to be more explicit about what's a key and what's not
        expect(extracted_key).to be_nil
      end
    end

    context 'given a branch name that does not contain a JIRA ticket key' do
      it 'does not find a ticket key' do
        extracted_key = subject.send(:extract_ticket_key_from_branch_name, 'super-duper-feature')
        expect(extracted_key).to be_nil
      end
    end
  end

  describe '#url_for_repo_and_sha' do
    context 'given a valid repo name and sha' do
      it 'returns a valid feature release URL' do
        url = subject.send(:url_for_repo_and_sha, full_repo_name, after_sha)
        expect(url).to eq "https://localhost/feature_reviews?apps%5B#{repo_name}%5D=#{after_sha}"
      end
    end
  end
end
