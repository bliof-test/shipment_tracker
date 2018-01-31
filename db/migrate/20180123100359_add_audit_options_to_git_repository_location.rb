class AddAuditOptionsToGitRepositoryLocation < ActiveRecord::Migration
  def change
    add_column :git_repository_locations, :audit_options, :text, array: true, default: []
  end
end
