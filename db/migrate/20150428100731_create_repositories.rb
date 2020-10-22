class CreateRepositories < ActiveRecord::Migration[4.2]
  def change
    create_table :repositories do |t|
      t.string :uri
      t.string :name

      t.timestamps null: false
    end
    add_index :repositories, :name, unique: true
  end
end
