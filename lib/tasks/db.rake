desc 'create database.yml based on database.yml.erb'
task 'db:create_database_yml' do
  require 'dotenv'
  require 'erb'
  Dotenv.load
  config_dir = File.expand_path('../../config', File.dirname(__FILE__))
  file_contents = File.read("#{config_dir}/database.yml.erb")

  File.open("#{config_dir}/database.yml", 'w') do |f|
    f.write ERB.new(file_contents).result
  end
end
