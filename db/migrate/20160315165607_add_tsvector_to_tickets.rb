class AddTsvectorToTickets < ActiveRecord::Migration
  def up
    add_column :released_tickets, :tsv, 'tsvector'
    add_index :released_tickets, :tsv, using: 'gin'

    execute <<-SQL
      CREATE OR REPLACE FUNCTION released_tickets_trigger() RETURNS trigger AS $$
      begin
        new.tsv :=
          setweight(to_tsvector('pg_catalog.english', coalesce(new.summary, '')), 'A') ||
          setweight(to_tsvector('pg_catalog.english', coalesce(new.description, '')), 'D');
        return new;
      end
      $$ LANGUAGE plpgsql;
    SQL

    execute <<-SQL
      CREATE TRIGGER released_tickets_tsv_update
      BEFORE INSERT OR UPDATE ON released_tickets
      FOR EACH ROW EXECUTE PROCEDURE released_tickets_trigger();
    SQL

    now = Time.current.to_s(:db)
    update("UPDATE released_tickets SET updated_at = '#{now}'")
  end

  def down
    remove_index :released_tickets, :tsv
    remove_column :released_tickets, :tsv

    execute <<-SQL
      DROP TRIGGER IF EXISTS released_tickets_tsv_update
      ON released_tickets
    SQL

    execute <<-SQL
      DROP FUNCTION IF EXISTS released_tickets_trigger();
    SQL
  end
end
