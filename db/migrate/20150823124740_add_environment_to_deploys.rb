class AddEnvironmentToDeploys < ActiveRecord::Migration[4.2]
  def change
    add_column :deploys, :environment, :string
  end
end
