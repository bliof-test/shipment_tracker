# frozen_string_literal: true

module Payloads
  class GithubPullRequest
    def initialize(data)
      @data = data
    end

    def pull_request
      @data['pull_request']
    end

    def created?
      @data['action'] == 'opened'
    end

    def updated?
      @data['action'] == 'synchronize'
    end

    def closed?
      @data['action'] == 'closed'
    end

    def merged?
      closed? && pull_request['merged']
    end

    def before_sha
      merged? ? base_sha : @data['before']
    end

    def after_sha
      merged? ? merge_commit_sha : @data['after']
    end

    def head_sha
      pull_request&.dig('head', 'sha')
    end

    def base_sha
      pull_request&.dig('base', 'sha')
    end

    def merge_commit_sha
      pull_request['merge_commit_sha']
    end

    def repo_name
      pull_request&.dig('base', 'repo', 'name')
    end

    def full_repo_name
      pull_request&.dig('base', 'repo', 'full_name')
    end

    def branch_name
      pull_request&.dig('head', 'ref')
    end

    def base_branch_master?
      %w[main master].include? pull_request&.dig('base', 'ref')
    end

    def title
      pull_request['title']
    end
  end
end
