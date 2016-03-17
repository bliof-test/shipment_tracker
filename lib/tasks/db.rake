namespace :db do
  desc 'create database.yml based on database.yml.erb'
  task 'create_database_yml' do
    require 'dotenv'
    require 'erb'
    Dotenv.load
    config_dir = File.expand_path('../../config', File.dirname(__FILE__))
    file_contents = File.read("#{config_dir}/database.yml.erb")

    File.open("#{config_dir}/database.yml", 'w') do |f|
      f.write ERB.new(file_contents).result
    end
  end

  desc 'reindex released tickets if indexing trigger exists'
  task :reindex_tickets => :environment do
    check_trigger_exists_and_reindex
  end

  def check_trigger_exists_and_reindex
    @connection = ActiveRecord::Base.connection
    result = @connection.exec_query(
      "SELECT tgname FROM pg_trigger WHERE not tgisinternal AND tgrelid = 'released_tickets'::regclass"
    )

    if result.first[:tgname] == 'released_tickets_tsv_update'
      puts "ERROR: Trigger does not exist for released_tickets relation, aborting!"
      puts "Tickets were not indexed"
      return
    end

    now = Time.current.to_s(:db)
    @connection.exec_query("UPDATE released_tickets SET updated_at = '#{now}'")
    puts "Tickets indexed successfully =)"
  end
end
