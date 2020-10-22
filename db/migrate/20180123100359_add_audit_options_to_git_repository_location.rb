class AddAuditOptionsToGitRepositoryLocation < ActiveRecord::Migration[4.2]
  def change
    add_column :git_repository_locations, :audit_options, :text, array: true, default: []
  end
end
