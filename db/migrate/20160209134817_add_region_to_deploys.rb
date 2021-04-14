class AddRegionToDeploys < ActiveRecord::Migration[4.2]
  def change
    add_column :deploys, :region, :string
  end
end
