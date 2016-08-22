# frozen_string_literal: true
require 'virtus'

class ReleasedTicket
  include Virtus.value_object

  values do
    attribute :key, String
    attribute :summary, String, default: ''
    attribute :description, String, default: ''
    attribute :versions, Array, default: []
    attribute :deploys, Array, default: []
  end

  def merges
    merges_from_deploys(deploys)
  end

  private

  attr_reader :merges_from_deploys

  def merges_from_deploys(deploys)
    uniq_deploys = deploys.uniq { |deploy| [deploy['app'], deploy['version']] }
    @merges_from_deploys ||= uniq_deploys.map { |deploy| Merge.new(build_hash(deploy)) }
  end

  def build_hash(deploy)
    { app_name: deploy['app'] }.merge(commit_info(deploy)).merge(related_deploys(deploy))
  end

  def commit_info(deploy)
    git_repository_loader ||= GitRepositoryLoader.from_rails_config.load(deploy['app'])
    merged_commit = git_repository_loader.commit_for_version(deploy['version'])
    { sha: merged_commit.id, merged_by: merged_commit.author_name, merged_at: merged_commit.time }
  end

  def related_deploys(deploy)
    related_deploys = deploys.select { |merge_deploy|
      merge_deploy['app'] == deploy['app'] && merge_deploy['version'] == deploy['version']
    }
    { deploys: related_deploys }
  end
end
