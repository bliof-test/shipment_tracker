# frozen_string_literal: true
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

    context 'when posting fails' do
      context 'because of HTTP 404' do
        let(:error) { JIRA::HTTPError.new(response) }
        let(:response) { double('response', message: 'Not Found', code: '404') }

        it 'raises InvalidKeyError' do
          allow(JIRA::Client).to receive(:new).and_raise(error)
          expect { JiraClient.post_comment('key', 'msg') }.to raise_error(JiraClient::InvalidKeyError)
        end
      end

      context 'because of not HTTP 404' do
        let(:error) { JIRA::HTTPError.new(response) }
        let(:response) { double('response', message: 'Server error', code: '500') }

        it 'raises InvalidKeyError' do
          allow(JIRA::Client).to receive(:new).and_raise(error)
          expect { JiraClient.post_comment('key', 'msg') }.to raise_error(error)
        end
      end
    end
  end
end
