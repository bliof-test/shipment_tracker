class CreateTokens < ActiveRecord::Migration[4.2]
  def change
    create_table :tokens do |t|
      t.string :source
      t.string :value

      t.timestamps null: false
    end
    add_index :tokens, :value, unique: true
  end
end
