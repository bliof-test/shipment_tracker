class AddTsvectorToTickets < ActiveRecord::Migration
  def up
    add_column :tickets, :tsv, 'tsvector'
    add_index :tickets, :tsv, using: "gin"

    execute <<-SQL
      UPDATE tickets SET tsv = setweight(to_tsvector(coalesce(summary,'')), 'A');
    SQL

    execute <<-SQL
      CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
      ON tickets FOR EACH ROW EXECUTE PROCEDURE
      tsvector_update_trigger(
        tsv, 'pg_catalog.english', summary
      );
    SQL
  end

  def down
    remove_column :tickets, :tsv

    execute <<-SQL
      DROP TRIGGER IF EXISTS tsvectorupdate ON tickets;
    SQL
  end
end
