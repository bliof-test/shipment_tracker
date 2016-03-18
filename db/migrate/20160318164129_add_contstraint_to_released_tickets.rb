class AddContstraintToReleasedTickets < ActiveRecord::Migration
  def up
    change_column(:released_tickets, :key, :string, unique: true)
    add_index(:released_tickets, :key, unique: true)
  end

  def down
    change_column(:released_tickets, :key, :string)
    remove_index(:released_tickets, :key)
  end
end
