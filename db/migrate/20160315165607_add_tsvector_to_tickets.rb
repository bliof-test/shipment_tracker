class AddTsvectorToTickets < ActiveRecord::Migration
  def up
    add_column :released_tickets, :tsv, :tsvector
    add_index :released_tickets, :tsv, using: :gin

    execute <<-SQL
      CREATE OR REPLACE FUNCTION released_tickets_trigger() RETURNS TRIGGER AS $$
      BEGIN
        new.tsv :=
          setweight(to_tsvector(coalesce(new.summary, '')), 'A') ||
          setweight(to_tsvector(coalesce(new.description, '')), 'D');
        RETURN new;
      END
      $$ LANGUAGE plpgsql;
    SQL

    # TODO: verify each does not do every record
    execute <<-SQL
      CREATE TRIGGER released_tickets_tsv_update
      BEFORE INSERT OR UPDATE ON released_tickets
      FOR ROW EXECUTE PROCEDURE released_tickets_trigger();
    SQL
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
