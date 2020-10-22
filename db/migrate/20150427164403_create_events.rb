class CreateEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :events do |t|
      t.json :details

      t.timestamps null: false
    end
  end
end
