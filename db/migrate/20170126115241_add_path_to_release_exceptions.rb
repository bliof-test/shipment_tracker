class AddPathToReleaseExceptions < ActiveRecord::Migration
  def change
    add_column :release_exceptions, :path, :string
  end
end
