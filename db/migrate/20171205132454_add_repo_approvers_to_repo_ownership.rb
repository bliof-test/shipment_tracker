class AddRepoApproversToRepoOwnership < ActiveRecord::Migration
  def change
    add_column :repo_ownerships, :repo_approvers, :string
  end
end
