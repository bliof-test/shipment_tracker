class AddPathToReleaseExceptions < ActiveRecord::Migration[4.2]
  def change
    add_column :release_exceptions, :path, :string
  end
end
