class AddUrlAppNameAndBuildTypeToBuilds < ActiveRecord::Migration[4.2]
  def change
    add_column :builds, :url, :string
    add_column :builds, :app_name, :string
    add_column :builds, :build_type, :string, default: 'unit'
  end
end
