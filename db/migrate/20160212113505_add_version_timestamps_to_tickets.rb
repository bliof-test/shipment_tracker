class AddVersionTimestampsToTickets < ActiveRecord::Migration[4.2]
  def change
    enable_extension 'hstore'
    add_column :tickets, :version_timestamps, :hstore, default: '', null: false
  end
end
