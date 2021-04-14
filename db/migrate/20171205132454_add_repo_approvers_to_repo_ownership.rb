class AddRepoApproversToRepoOwnership < ActiveRecord::Migration[4.2]
  def change
    add_column :repo_ownerships, :repo_approvers, :string
  end
end
