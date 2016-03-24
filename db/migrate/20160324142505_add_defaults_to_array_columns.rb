class AddDefaultsToArrayColumns < ActiveRecord::Migration
  def change
    change_column :tickets, :paths, :text, array: true, default: []
    change_column :tickets, :versions, :text, array: true, default: []
    change_column :uatests, :versions, :text, array: true, default: []
    change_column :manual_tests, :versions, :text, array: true, default: []
    change_column :released_tickets, :versions, :text, array: true, default: []
  end
end
