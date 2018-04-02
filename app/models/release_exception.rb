# frozen_string_literal: true

class ReleaseException
  include Virtus.value_object

  values do
    attribute :repo_owner_id, Integer
    attribute :comment, String
    attribute :approved, Boolean
    attribute :submitted_at, Time
    attribute :path, String
    attribute :versions, Array, default: []
  end

  def commits
    versions.map { |version| GitCommit.new(id: version) }
  end

  def repo_owner
    RepoAdmin.find(repo_owner_id)
  end

  def approved_at
    approved ? submitted_at : nil
  end

  def declined_at
    approved ? nil : submitted_at
  end
end
