class AddDeploysToReleasedTickets < ActiveRecord::Migration
  def up
    add_column :released_tickets, :deploys, :json, default: []

    execute <<-SQL
      CREATE OR REPLACE FUNCTION deployed_apps(deploys json) RETURNS VARCHAR AS $$
      BEGIN
        RETURN (SELECT string_agg(elem::json->>'app', ' ')
                FROM json_array_elements_text(deploys) elem);
      END
      $$ LANGUAGE plpgsql;
    SQL

    execute <<-SQL
      CREATE OR REPLACE FUNCTION released_tickets_trigger() RETURNS TRIGGER AS $$
      BEGIN
        new.tsv :=
          setweight(to_tsvector(coalesce(deployed_apps(new.deploys), '')), 'A') ||
          setweight(to_tsvector(coalesce(new.summary, '')), 'B') ||
          setweight(to_tsvector(coalesce(new.description, '')), 'D');
        RETURN new;
      END
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    remove_column :released_tickets, :deploys

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
  end
end
