class AddUuidToEvents < ActiveRecord::Migration[4.2]
  def change
    enable_extension 'uuid-ossp'
    add_column :events, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :events, :uuid, unique: true
  end
end
