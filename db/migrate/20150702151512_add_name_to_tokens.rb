class AddNameToTokens < ActiveRecord::Migration[4.2]
  def change
    add_column :tokens, :name, :string
  end
end
