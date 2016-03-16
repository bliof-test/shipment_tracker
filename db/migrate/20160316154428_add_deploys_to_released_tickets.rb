class AddDeploysToReleasedTickets < ActiveRecord::Migration
  def up
    add_column :released_tickets, :deploys, :json, default: []

    # Note: JSON index for app name on deploys column needs to be of type int
    # to get JSON array element. Using `deploys->>'app'` does not work
    # because it tries to get JSON object field.
    # http://www.postgresql.org/docs/9.4/static/functions-json.html
    execute <<-SQL
      CREATE OR REPLACE FUNCTION released_tickets_trigger() RETURNS trigger AS $$
      begin
        new.tsv :=
          -- setweight(to_tsvector(coalesce('#{app_names}', '')), 'A') ||
          -- setweight(to_tsvector(coalesce(my_function(new.deploys), '')), 'A') ||
          -- setweight(to_tsvector(coalesce(new.deployed_apps, '')), 'A') ||
          setweight(to_tsvector(coalesce(new.deploys->>0, '')), 'A') ||
          setweight(to_tsvector(coalesce(new.summary, '')), 'B') ||
          setweight(to_tsvector(coalesce(new.description, '')), 'D');
        return new;
      end
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    remove_column :released_tickets, :deploys

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
  end
end
