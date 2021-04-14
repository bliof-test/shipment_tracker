class RenameUrlsOnTicketsToPaths < ActiveRecord::Migration[4.2]
  def change
    rename_column :tickets, :urls, :paths
  end
end
