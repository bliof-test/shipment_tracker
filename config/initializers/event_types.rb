# frozen_string_literal: true

Rails.application.config.event_types = [
  EventType.new(
    name: 'CircleCI (webhook)',
    endpoint: 'circleci',
    event_class: Events::CircleCiEvent,
  ),
  EventType.new(
    name: 'CircleCI (post test)',
    endpoint: 'circleci-manual',
    event_class: Events::CircleCiManualWebhookEvent,
  ),
  EventType.new(
    name: 'Deployment',
    endpoint: 'deploy',
    event_class: Events::DeployEvent,
  ),
  EventType.new(
    name: 'Jenkins',
    endpoint: 'jenkins',
    event_class: Events::JenkinsEvent,
  ),
  EventType.new(
    name: 'JIRA',
    endpoint: 'jira',
    event_class: Events::JiraEvent,
  ),
  EventType.new(
    name: 'Manual test',
    endpoint: 'manual_test',
    event_class: Events::ManualTestEvent, internal: true
  ),
  EventType.new(
    name: 'Repo Ownership',
    endpoint: 'repo_ownership',
    event_class: Events::RepoOwnershipEvent, internal: true
  ),
  EventType.new(
    name: 'Project Owner Exception',
    endpoint: 'release_exception',
    event_class: Events::ReleaseExceptionEvent, internal: true
  ),
  EventType.new(
    name: 'Deploy Alert',
    endpoint: 'deploy_alert',
    event_class: Events::DeployAlertEvent, internal: true
  ),
]
