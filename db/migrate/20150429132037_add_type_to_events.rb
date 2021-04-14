class AddTypeToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :type, :string
  end
end
