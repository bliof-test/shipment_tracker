require 'rails_helper'
require 'clients/jira'

RSpec.describe JiraClient do
  before do
    allow(comment_mock).to receive(:save)
    allow(comments_mock).to receive(:build).and_return(comment_mock)
    allow(issue_mock).to receive(:comments).and_return(comments_mock)
    allow(client_mock).to receive_message_chain(:Issue, :find).and_return(issue_mock)
    allow(JIRA::Client).to receive(:new).and_return(client_mock)
  end

  describe '.post_comment' do
    let(:client_mock) { double }
    let(:issue_mock) { double }
    let(:comments_mock) { double }
    let(:comment_mock) { double }

    it 'creates a Jira::Client' do
      expect(JIRA::Client).to receive(:new).with(hash_including(
                                                   username: anything,
                                                   password: anything,
                                                   site: anything,
                                                   context_path: anything,
                                                   auth_type: anything,
                                                   read_timeout: anything,
      ))
      JiraClient.post_comment('ISSUE-ID', 'Comment text')
    end

    it 'creates comment with correct message' do
      expect(comment_mock).to receive(:save).with(body: 'comment text')
      JiraClient.post_comment('ISSUE-ID', 'comment text')
    end
  end
end
