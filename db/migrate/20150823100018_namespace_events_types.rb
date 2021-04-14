class NamespaceEventsTypes < ActiveRecord::Migration[4.2]
  def up
    execute(%{
      UPDATE events
      SET type=('Events::' || type)
    })
  end

  def down
    execute(%{
      UPDATE events
      SET type=ltrim(type, 'Events::')
    })
  end
end
