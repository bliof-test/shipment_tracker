# frozen_string_literal: true
Then 'a deploy alert should be dispatched for' do |table|
  table.hashes.each do |row|
    method, app, time, deployer, version, msg, to =
      row.values_at('method', 'app_name', 'time', 'deployer', 'version', 'message', 'to')

    case method
    when 'slack'
      expect(SlackClient).to have_received(:send_deploy_alert).with(
        "GB Deploy Alert for #{app} at #{time}.\n"\
        "#{deployer} deployed #{scenario_context.resolve_version(version)}.\n#{msg}",
        'https://localhost/releases/frontend?region=gb',
        app,
        deployer,
      )
    when 'email'
      repo_owners = Repositories::RepoOwnershipRepository.new.owners_of('frontend')

      expect(repo_owners.map(&:email)).to include(to)

      deployed_at = Time.parse(time)

      expect(DeployAlertMailer).to have_received(:deploy_alert_email).with(
        repo_owners: repo_owners,
        repo: 'frontend',
        region: 'gb',
        deployer: deployer,
        deployed_at: deployed_at,
        alert: [
          "GB Deploy Alert for #{app} at #{deployed_at.strftime('%F %H:%M%:z')}.",
          "#{deployer} deployed #{scenario_context.resolve_version(version)}.",
          msg,
        ].join("\n"),
        releases_url: 'https://localhost/releases/frontend?region=gb',
      )
    end
  end
end

Then 'a deploy alert should not be dispatched' do
  expect(SlackClient).to_not have_received(:send_deploy_alert)
end
