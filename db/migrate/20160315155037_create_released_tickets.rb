class CreateReleasedTickets < ActiveRecord::Migration[4.2]
  def change
    create_table :released_tickets do |t|
      t.string :key
      t.string :summary
      t.text :description
      t.timestamps null: false
    end
  end
end
