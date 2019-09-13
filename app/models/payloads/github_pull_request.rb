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

    def before_sha
      @data['before']
    end

    def after_sha
      @data['after']
    end

    def head_sha
      pull_request&.dig('head', 'sha')
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
      pull_request&.dig('base', 'ref') == 'master'
    end
  end
end
