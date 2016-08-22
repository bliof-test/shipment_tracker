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

  def merges_from_deploys(deploys)
    uniq_deploys = deploys.uniq { |deploy| [deploy['app'], deploy['version']] }
    uniq_deploys.map { |deploy| Merge.new(build_hash(deploy)) }
  end

  def build_hash(deploy)
    { app_name: deploy['app'],
      deploys: related_deploys(deploy) }
      .merge(commit_info(deploy))
  end

  def commit_info(deploy)
    merged_commit = git_repository_loader_for(deploy['app']).commit_for_version(deploy['version'])
    { sha: merged_commit.id, merged_by: merged_commit.author_name, merged_at: merged_commit.time }
  end

  def related_deploys(deploy)
    deploys.select { |merge_deploy|
      merge_deploy['app'] == deploy['app'] && merge_deploy['version'] == deploy['version']
    }
  end

  def git_repository_loader_for(app_name)
    @git_repository_loader ||= GitRepositoryLoader.from_rails_config.load(app_name)
  end
end
