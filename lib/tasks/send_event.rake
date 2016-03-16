# frozen_string_literal: true
namespace :send do
  desc 'Sends a sample UAT event'
  task :uat_event, [:success, :test_suite_version, :server, :url] do |_, args|
    usage = 'Usage: rake "send:uat_event[true, s0m3c0mm1t, uat.example.com, '\
            'http://shipment_tracker.url/events/uat?token=s0m3t0k3n]"'
    abort(usage) if args.to_hash.empty?

    send_event(
      args[:url],
      success: args[:success] == 'true',
      test_suite_version: args[:test_suite_version],
      server: args[:server],
    )
  end

  desc 'Sends a sample deploy event'
  task :deploy_event, [:app_name, :version, :server, :environment, :url, :region, :deployer] do |_, args|
    usage = 'Usage: rake "send:deploy_event[app_name, s0m3c0mm1t, app_name.example.com, production, '\
            'http://shipment_tracker.url/events/deploy?token=s0m3t0k3n, gb, a_user]"'
    abort(usage) if args.to_hash.empty?

    send_event(
      args[:url],
      server: args[:server],
      environment: args[:environment],
      version: args[:version],
      app_name: args[:app_name],
      locale: args[:region],
      deployed_by: args[:deployer],
    )
  end

  def send_event(url, payload)
    command = "curl -H 'Content-Type: application/json' -X POST -d '#{payload.to_json}' #{url}"
    puts command
    system command
  end
end
