# frozen_string_literal: true

module Payloads
  class Github
    BRANCH_NAME_REGEX = %r{^refs\/.+\/(?<branch_name>.+)$}.freeze

    def initialize(data)
      @data = data
    end

    def before_sha
      @data['before']
    end

    def after_sha
      @data['after']
    end

    def head_sha
      @data.dig('head_commit', 'id')
    end

    def base_repo_url
      @data.dig('repository', 'html_url')
    end

    def full_repo_name
      @data.dig('repository', 'full_name')
    end

    def push_annotated_tag?
      !!(ref&.start_with?('refs/tags/') && base_ref.nil?)
    end

    def push_to_master?
      branch_name == 'master'
    end

    def branch_created?
      @data['created']
    end

    def branch_deleted?
      @data['deleted']
    end

    def branch_name
      matches = @data['ref'].match(BRANCH_NAME_REGEX)
      matches[:branch_name] if matches
    end

    private

    def ref
      @data['ref']
    end

    def base_ref
      @data['base_ref']
    end
  end
end
