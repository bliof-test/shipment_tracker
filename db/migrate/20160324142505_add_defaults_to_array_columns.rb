class AddDefaultsToArrayColumns < ActiveRecord::Migration[4.2]
  def up
    change_column :tickets, :paths, :text, array: true, default: []
    change_column :tickets, :versions, :text, array: true, default: []
    change_column :uatests, :versions, :text, array: true, default: []
    change_column :manual_tests, :versions, :text, array: true, default: []
    change_column :released_tickets, :versions, :text, array: true, default: []
  end

  def down
    change_column :tickets, :paths, :text, array: true
    change_column :tickets, :versions, :string, array: true
    change_column :uatests, :versions, :text, array: true
    change_column :manual_tests, :versions, :string, array: true
    change_column :released_tickets, :versions, :string, array: true
  end
end
