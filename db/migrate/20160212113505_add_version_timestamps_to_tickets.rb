class AddVersionTimestampsToTickets < ActiveRecord::Migration
  def change
    enable_extension 'hstore'
    add_column :tickets, :version_timestamps, :hstore, default: '', null: false
  end
end
