# frozen_string_literal: true
require 'virtus'

class GitCommit
  include Virtus.value_object

  values do
    attribute :id, String
    attribute :author_name, String
    attribute :message, String
    attribute :time, Time
    attribute :parent_ids, Array
  end

  def subject_line
    message.split("\n").first
  end

  def associated_ids
    [id, merged_branch_head_commit].compact
  end

  private

  def merged_branch_head_commit
    parent_ids[1]
  end
end
