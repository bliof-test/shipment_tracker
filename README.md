# Shipment Tracker <sup>*:sparkles:[See the wiki for usage docs][wiki]:sparkles:*</sup>

[![CircleCI](https://circleci.com/gh/FundingCircle/shipment_tracker/tree/master.svg?style=shield)](https://circleci.com/gh/FundingCircle/shipment_tracker/tree/master)
[![Code Climate](https://codeclimate.com/github/FundingCircle/shipment_tracker/badges/gpa.svg)](https://codeclimate.com/github/FundingCircle/shipment_tracker)
[![Test Coverage](https://codeclimate.com/github/FundingCircle/shipment_tracker/badges/coverage.svg)](https://codeclimate.com/github/FundingCircle/shipment_tracker/coverage)

[![](http://i.imgur.com/VkjlJmj.jpg)](https://www.flickr.com/photos/britishlibrary/11237769263/)

Tracks software versions during the release cycle for audit purposes.

The app has various "audit endpoints" to receive events,
such as deploys, builds, ticket creations, etc.

All received events are stored in the DB and are never modified.  
[Event sourcing] is used to replay each event allowing us to reconstruct the state
of the system at any point in time.

## Getting Started

Install the Ruby version specified in `.ruby-version`.

Install the Gems.

```
bundle install
```

Setup database and environment.

```
cp .env.development.example .env.development
cp config/database.yml.example config/database.yml
bundle exec rake db:setup
```

Set up Git hooks, for running tests and linters before pushing to master.

```
bundle exec rake git:setup_hooks
```

### Enabling access to repositories via SSH

Ensure that `libssh2` is installed and the `rugged` gem is reinstalled. On OSX:

```
brew install libssh2
gem pristine rugged
```

When booting server, set Environment variables `SSH_USER`, `SSH_PUBLIC_KEY` and `SSH_PRIVATE_KEY`:

```
SSH_USER=git \
SSH_PUBLIC_KEY='ssh-rsa AAAXYZ' \
SSH_PRIVATE_KEY='-----BEGIN RSA PRIVATE KEY-----
abcdefghijklmnopqrstuvwxyz
-----END RSA PRIVATE KEY-----' \
rails s -p 1201
```

Note that port 1201 is only needed in development; it's the expected port by auth0 (the service we use for authentication).

You can also use Foreman to start the server

```
foreman start --port 1201
```

### Snapshotting events

Shipment Tracker needs to continuously record snapshots for incoming events that it processes.  
The rake task `jobs:update_events_loop` should be used to do this.  
We suggest running it as a background job (e.g. using Supervisor or a Heroku worker).

*Warning:* This recurring task should only run on **one** server.

### Enable Git fetching

It's important to keep the repositories tracked by Shipment Tracker reasonably up-to-date.

Please make sure the following command runs as a background task:

```
bundle exec rake jobs:update_git_loop
```

*Warning:* Unless the git cache is on a shared directory this recurring task should run on **every** server that your application is running on.

In addition to the `update_git_loop` task, you can set the environment variable
`ALLOW_GIT_FETCH_ON_REQUEST=true` if you also want the git repositories to be updated on web request
(e.g. when preparing a Feature Review).

### Enable GitHub Webhooks

[Configure GitHub webhooks][webhooks] at an organization-wide level or per repository for **pull request** notifications.

Shipment Tracker uses GitHub pull request notifications to update the repositories that it tracks, and to show
a Shipment Tracker status check.

To configure the webhook
 1. In GitHub, add a new webhook in the repository or organisation settings.
 2. In the API Tokens tab of Shipment Tracker, find (or create) a Github Notifications token.
 3. Set "Payload URL" to the GitHub notifications URL from Shipment Tracker.
 4. Set "Content type" to "application/json".
 5. Select "Let me select individual events."
 6. Select "Pull requests".
 7. Click "Add webhook"

You'll also need a [GitHub Access Token][access tokens] for authentication with the GitHub API.

There are two environment variables for GitHub tokens.

| Environment variable | Description |
| --- | --- |
| `GITHUB_REPO_READ_TOKEN` | For validation when onboarding a new repository.<br>Should have `repo` scope. Token owner must have READ access to repositories. |
| `GITHUB_REPO_STATUS_WRITE_TOKEN` | For creating commit statuses in Pull Requests.<br>Should have `repo:status` scope. Token owner must have WRITE access to repositories. |

Recommended to use two different tokens, from two different users (one with READ access, one with WRITE),
instead of one super token.

### Maintenance mode

There is a rake task `jobs:recreate_snapshots` for recreating snapshots.
You'll want to recreate snapshots if you changed the schema of a snapshots database table for example.

When recreating snapshots, you can put the application into maintenance mode.
This temporarily disables GitHub status notifications, deploy alerts,
and notifies users that some data may appear out of date.

To enable maintenance mode, set the environment variable `DATA_MAINTENANCE=true` and reboot the application.  
To disable maintenance mode, set the environment variable to `false` and reboot the application.

### Configure alerts

Shipment Tracker can send alerts when deployment rules are violated.
[More information](https://github.com/FundingCircle/shipment_tracker/wiki/Alerting) can be found in the wiki.

To configure Slack alerts

1. Create a Slack webhook for a specific channel and copy the webhook URL
1. Set the environment variable `SLACK_WEBHOOK` with the webhook URL

### Docker Compose

```
cp secrets.env.example secrets.env
```

Add secrets to `secrets.env`

`SSH_PRIVATE_KEY` is multi line so cannot be added to `secrets.env`. It must be set in the environment.

```
export SSH_PRIVATE_KEY=...
```

Start the application with docker-compose:
```
docker-compose build
docker-compose up -d web
docker-compose run git-worker
```

To debug the web service with pry:
```
docker-compose run --service-ports web
```

## License

Copyright © 2015-2016 Funding Circle Ltd.

Distributed under the BSD 3-Clause License.

[wiki]: ../../wiki/
[Event sourcing]: http://www.infoq.com/presentations/Events-Are-Not-Just-for-Notifications
[webhooks]: https://help.github.com/articles/about-webhooks/
[access tokens]: https://help.github.com/articles/creating-an-access-token-for-command-line-use/
