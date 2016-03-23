Given 'a ticket "$key" with summary "$summary" is started at "$time"' do |key, summary, time|
  scenario_context.create_and_start_ticket(
    key: key,
    summary: summary,
    time: time,
  )
end

Given 'the following tickets are created:' do |tickets_table|
  tickets_table.hashes.each do |ticket_row|
    scenario_context.create_and_start_ticket(
      key: ticket_row['Jira Key'],
      summary: ticket_row['Summary'],
      description: ticket_row['Description'],
    )

    deploys = ticket_row['Deploys']
    next if deploys.empty?
    date, time, app_name, deploy_sha = deploys.split
    datetime = Time.zone.parse("#{date} #{time}")
    fr = "FR_#{app_name}"
    ticket = ticket_row['Jira Key']

    steps %(
      Given an application called "#{app_name}"

      And a commit "#master_1" by "Alice" is created at "#{(datetime - 5.hours)}" for app "#{app_name}"
      And the branch "feature" is checked out
      And a commit "#feat_1_#{app_name}" with message "some commit" is created at "#{(datetime - 4.hours)}"
      And the branch "master" is checked out
      And the branch "feature" is merged with merge commit "#{deploy_sha}" at "#{(datetime - 3.hours)}"

      And developer prepares review known as "#{fr}" for UAT "uat.fundingcircle.com" with apps
        | app_name    | version             |
        | #{app_name} | #feat_1_#{app_name} |

      And at time "#{(datetime - 2.hours)}" adds link for review "#{fr}" to comment for ticket "#{ticket}"

      And ticket "#{ticket}" is approved by "bob@fundingcircle.com" at "#{(datetime - 1.hour)}"

      And commit "#{deploy_sha}" of "#{app_name}" is deployed by "Jeff" to production at "#{datetime}"
    )
  end
end

Given 'at time "$a" adds link for review "$b" to comment for ticket "$c"' do |time, nickname, jira_key|
  scenario_context.link_ticket_and_feature_review(
    jira_key: jira_key,
    feature_review_nickname: nickname,
    time: time,
  )
end

Given 'ticket "$key" is approved by "$approver_email" at "$time"' do |jira_key, approver_email, time|
  scenario_context.approve_ticket(
    jira_key: jira_key,
    approver_email: approver_email,
    approve: true,
    time: time,
  )
end

Given 'ticket "$key" is moved from approved to unapproved by "$email" at "$time"' do |jira_key, email, time|
  scenario_context.approve_ticket(
    jira_key: jira_key,
    approver_email: email,
    approve: false,
    time: time,
  )
end

Given 'At "$time" CircleCi "$outcome" for commit "$version"' do |time, outcome, version|
  payload = build(
    :circle_ci_manual_webhook_event,
    success?: outcome == 'passes',
    version: scenario_context.resolve_version(version),
  ).details

  travel_to Time.zone.parse(time) do
    scenario_context.post_event 'circleci-manual', payload
  end
end

# rubocop:disable LineLength
Given 'commit "$version" of "$app" is deployed by "$name" to server "$server" at "$time"' do |version, app, name, server, time|
  payload = build(
    :deploy_event,
    server: server,
    app_name: app,
    locale: 'gb',
    version: scenario_context.resolve_version(version),
    deployed_by: name,
  ).details

  travel_to Time.zone.parse(time) do
    scenario_context.post_event 'deploy', payload
  end
end
# rubocop:enable LineLength

Given 'commit "$ver" of "$app" is deployed by "$name" to production at "$time"' do |ver, app, name, time|
  payload = build(
    :deploy_event,
    server: "#{app}.example.com",
    environment: 'production',
    app_name: app,
    locale: 'gb',
    version: scenario_context.resolve_version(ver),
    deployed_by: name,
  ).details

  travel_to Time.zone.parse(time) do
    scenario_context.post_event 'deploy', payload
  end
end

# rubocop:disable LineLength
Given 'User Acceptance Tests at version "$sha" which "$outcome" on server "$server" at "$time"' do |sha, outcome, server, time|
  payload = build(
    :uat_event,
    success: outcome == 'passed',
    test_suite_version: sha,
    server: server,
  ).details

  travel_to Time.zone.parse(time) do
    scenario_context.post_event 'uat', payload
  end
end
# rubocop:enable LineLength

When 'snapshots are regenerated' do
  repos = Rails.configuration.repositories
  updater = Repositories::Updater.new(repos)
  updater.reset
  updater.run
end
