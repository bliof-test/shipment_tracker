class RenameRepoOwnersToRepoAdmins < ActiveRecord::Migration
  def change
    rename_table :repo_owners, :repo_admins
  end
end
