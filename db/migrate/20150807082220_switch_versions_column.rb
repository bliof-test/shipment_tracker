class SwitchVersionsColumn < ActiveRecord::Migration[4.2]
  def change
    remove_column(:uatests, :versions, :jsonb)
    add_column(:uatests, :versions, :text, array: true)
  end
end
