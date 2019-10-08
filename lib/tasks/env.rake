# frozen_string_literal: true

namespace :env do
  desc 'Load .env.assets that allows production assets compilation without all production env variables'
  task :assets do
    require 'dotenv'
    Dotenv.load('.env.assets')
  end
end

task 'assets:environment' => 'env:assets'
