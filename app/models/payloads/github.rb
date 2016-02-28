module Payloads
  class Github
    def initialize(data)
      @data = data
    end

    def after_sha
      @data['after']
    end

    def head_sha
      @data.dig('pull_request', 'head', 'sha')
    end

    def base_repo_url
      @data.dig('pull_request', 'base', 'repo', 'html_url')
    end

    def full_repo_name
      @data.dig('repository', 'full_name')
    end

    def action
      @data['action']
    end
  end
end
