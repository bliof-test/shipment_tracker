class RenameRepoOwnersToRepoAdmins < ActiveRecord::Migration[4.2]
  def change
    rename_table :repo_owners, :repo_admins
  end
end
