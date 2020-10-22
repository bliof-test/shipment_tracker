class AddIndexForKeyToTickets < ActiveRecord::Migration[4.2]
  def change
    add_index :tickets, :key
  end
end
