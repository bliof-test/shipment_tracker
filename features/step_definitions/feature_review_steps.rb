# frozen_string_literal: true
Given 'I prepare a feature review for:' do |table|
  prepare_feature_review_page.visit
  step 'I fill in the data for a feature review:', table
end

Given 'I fill in the data for a feature review:' do |table|
  table.hashes.each do |row|
    prepare_feature_review_page.add(
      field_name: row.fetch('field name'),
      content: scenario_context.resolve_version(row.fetch('content')),
    )
  end

  prepare_feature_review_page.submit
end

Then 'I should see the feature review page with the applications:' do |table|
  expected_app_info = table.hashes.map { |hash|
    version = hash.fetch('version')
    real_version = scenario_context.resolve_version(version)
    hash.merge('version' => real_version.slice(0..6))
  }

  expect(feature_review_page.app_info).to match_array(expected_app_info)
end

Given 'developer prepares review known as "$a" with apps' do |known_as, apps_table|
  scenario_context.prepare_review(apps_table.hashes, known_as)
end

When 'I visit the feature review known as "$known_as"' do |known_as|
  visit scenario_context.review_path(feature_review_nickname: known_as)
end

When 'I visit feature review "$known_as" as at "$time"' do |known_as, time|
  visit scenario_context.review_path(feature_review_nickname: known_as, time: time)
end

Then 'I should see the builds with heading "$status" and content' do |status, builds_table|
  expected_builds = builds_table.hashes
  expect(feature_review_page.panel_heading_status('builds')).to eq(status)
  expect(feature_review_page.builds).to match_array(expected_builds)
end

Then 'I should see the tickets' do |ticket_table|
  expected_tickets = ticket_table.hashes
  expect(feature_review_page.tickets).to match_array(expected_tickets)
end

Then(/^(I should see )?a summary with heading "([^\"]*)" and content$/) do |_, status, summary_table|
  expected_summary = summary_table.hashes

  panel = feature_review_page.summary_panel
  expect(panel.status).to eq(status)
  expect(panel.items).to match_array(expected_summary)
end

Then 'I should see a summary that includes' do |summary_table|
  expected_summary = summary_table.hashes

  panel = feature_review_page.summary_panel
  expect(panel.items).to include(*expected_summary)
end

When 'I "$action" the feature with comment "$comment" as a QA' do |action, comment|
  feature_review_page.create_submission(
    comment: comment,
    status: action,
    type: 'QA',
  )
end

When 'I "$action" the feature with comment "$comment" as a Repo Owner' do |action, comment|
  scenario_context.stub_github_update_for_repo_owner(action)
  feature_review_page.create_submission(
    comment: comment,
    status: action,
    type: 'Repo Owner',
  )
end

Then 'I should see the QA acceptance with heading "$status"' do |status|
  expect(feature_review_page.panel_heading_status('qa-submission')).to eq(status)
end

Then 'I should see the QA acceptance' do |table|
  expected_qa_submission = table.hashes.first
  status = expected_qa_submission.delete('status')
  panel = feature_review_page.qa_submission_panel

  expect(panel.status).to eq(status)
  expect(panel.items.first).to eq(expected_qa_submission)
end

Then 'I should see the Repo Owner Commentary with heading "$status"' do |status|
  expect(feature_review_page.panel_heading_status('release-exception')).to eq(status)
end

Then 'I should see the Repo Owner Commentary' do |table|
  expected_release_exception_comment_info = table.hashes.first
  status = expected_release_exception_comment_info.delete('status')
  panel = feature_review_page.release_exception_panel

  expect(panel.status).to eq(status)
  expect(panel.items.first).to eq(expected_release_exception_comment_info)
end

Then 'I should see the time "$time" for the Feature Review' do |time|
  expect(feature_review_page.time).to be_present
  expect(Time.zone.parse(feature_review_page.time)).to eq(Time.zone.parse(time))
end

Then 'I should see that the Feature Review was approved at "$time"' do |time|
  expected_time = Time.zone.parse(time).utc
  expect(feature_review_page.feature_status).to eq("Feature Status: Approved at #{expected_time}")
end

Then 'I should see that the Feature Review was not approved' do
  expect(feature_review_page.feature_status).to eq('Feature Status: Not approved')
end

Then 'I should see that the Feature Review requires reapproval' do
  expect(feature_review_page.feature_status).to eq('Feature Status: Requires reapproval')
end

When 'I reload the page after a while' do
  Repositories::Updater.from_rails_config.run
  page.visit(page.current_url)
end

When 'I click modify button on review panel' do
  page.click_link_or_button('Modify')
end

When 'I link the feature review "$nickname" to the Jira ticket "$jira_key"' do |nickname, jira_key|
  feature_review_page.link_a_jira_ticket(jira_key: jira_key)
  scenario_context.post_jira_comment(jira_key: jira_key, feature_review_nickname: nickname, comment_type: LinkTicket)
end

When 'I unlink the feature review "$nickname" from the Jira ticket "$jira_key"' do |nickname, jira_key|
  feature_review_page.unlink_a_jira_ticket(jira_key: jira_key)
  scenario_context.post_jira_comment(jira_key: jira_key, feature_review_nickname: nickname, comment_type: UnlinkTicket)
end
