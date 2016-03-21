require 'rails_helper'
require 'repositories/released_ticket_repository'
require 'snapshots/released_ticket'
require 'ticket'

RSpec.describe Repositories::ReleasedTicketRepository do
  subject(:ticket_repo) { Repositories::ReleasedTicketRepository.new(store) }

  describe '#tickets_for_query' do
    let(:store) { double }
    let(:query) { double }
    let(:ticket) { double(Snapshots::Ticket, attributes: {}) }

    before do
      allow(store).to receive(:search_for).and_return([ticket])
    end

    it 'delegates search to store' do
      ticket_repo.tickets_for_query(query)
      expect(store).to have_received(:search_for).with(query)
    end

    it 'returns Ticket objects' do
      tickets = ticket_repo.tickets_for_query(query)
      expect(tickets.first).to be_a_kind_of(Ticket)
    end

    context 'when no tickets found' do
      before do
        allow(store).to receive(:search_for).and_return([])
      end

      it 'returns empty array' do
        tickets = ticket_repo.tickets_for_query(query)
        expect(tickets).to be_empty
      end
    end
  end

  describe '#apply' do
    let(:store) { Snapshots::ReleasedTicket }
    let(:time) { Time.current }
    let(:event_attrs) {
      {
        'key' => 'JIRA-123',
        'summary' => 'some summary',
        'description' => 'some description',
      }
    }

    before do
      commit = instance_double(GitCommit, associated_ids: %w(abc def))
      repository = instance_double(GitRepository)
      repository_loader = instance_double(GitRepositoryLoader)

      allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(repository_loader)
      allow(repository_loader).to receive(:load).and_return(repository)
      allow(repository).to receive(:commit_for_version).and_return(commit)

      allow(GitRepositoryLocation).to receive(:github_url_for_app)
    end

    context 'when ticket snapshot exists' do
      it 'updates existing ticket when FR is being linked' do
        Snapshots::ReleasedTicket.create(key: 'JIRA-1', summary: 'foo', description: 'bar', versions: ['abc'])
        event = build(
          :jira_event,
          key: 'JIRA-1',
          summary: 'new title',
          description: 'new description',
          comment_body: feature_review_url(app1: 'def', app2: 'ghi'),
        )
        expect { ticket_repo.apply(event) }.to_not change { Snapshots::ReleasedTicket.count }

        expected_attributes = {
          'key' => 'JIRA-1',
          'summary' => 'new title',
          'description' => 'new description',
          'versions' => %w(abc def ghi),
        }
        expect(Snapshots::ReleasedTicket.last.attributes).to include(expected_attributes)
      end

      it 'updates existing ticket for any JIRA event' do
        Snapshots::ReleasedTicket.create(key: 'JIRA-1', summary: 'foo', description: 'bar', versions: ['abc'])
        event = build(
          :jira_event,
          key: 'JIRA-1',
          summary: 'new title',
          description: 'new description',
        )
        expect { ticket_repo.apply(event) }.to_not change { Snapshots::ReleasedTicket.count }

        expected_attributes = {
          'key' => 'JIRA-1',
          'summary' => 'new title',
          'description' => 'new description',
          'versions' => %w(abc),
        }
        expect(Snapshots::ReleasedTicket.last.attributes).to include(expected_attributes)
      end
    end

    context 'when no ticket snapshot exists' do
      context 'when ticket has Feature Reviews' do
        it 'snapshots' do
          event = build(:jira_event, event_attrs.merge(comment_body: feature_review_url(app: 'abc')))
          expect { ticket_repo.apply(event) }.to change { Snapshots::ReleasedTicket.count }.by(1)

          expected_attrs = event_attrs.merge('versions' => ['abc'])
          expect(Snapshots::ReleasedTicket.last.attributes).to include(expected_attrs)
        end
      end

      context 'when ticket has no Feature Reviews' do
        it 'does not snapshot' do
          event = build(:jira_event, event_attrs)
          expect { ticket_repo.apply(event) }.to_not change { Snapshots::ReleasedTicket.count }
        end
      end
    end

    describe 'applying deploy events' do
      let(:deploy_event) {
        build(:deploy_event, environment: 'production', version: version, created_at: time_string)
      }
      let(:version) { 'abc' }
      let(:time_string) { time.strftime('%F %H:%M %Z') }
      let(:gurl) { 'https://github.com/owner/hello_world' }

      context 'when deploy is to production' do
        context 'when deploy version is linked to some tickets' do
          let!(:released_ticket) {
            Snapshots::ReleasedTicket.create(
              key: 'JIRA-1',
              summary: 'foo',
              description: 'bar',
              versions: [version],
              deploys: [{
                'app' => 'hello_world',
                'version' => 'def123',
                'deployed_at' => time_string,
                'github_url' => gurl,
              }],
            )
          }

          before do
            allow(GitRepositoryLocation).to receive(:github_url_for_app).with('hello_world').and_return(gurl)
          end

          let(:expected_deploys) {
            [
              {
                'app' => 'hello_world',
                'version' => 'abc',
                'deployed_at' => time_string,
                'github_url' => gurl,
              },
              {
                'app' => 'hello_world',
                'version' => 'def123',
                'deployed_at' => time_string,
                'github_url' => gurl,
              },
            ]
          }

          it 'updates related tickets with the deploy info' do
            ticket_repo.apply(deploy_event)
            record = store.find_by_key('JIRA-1')
            expect(record.deploys).to match_array(expected_deploys)
          end

          context 'when the version was deployed already' do
            let(:yesterday_str) { (time - 1.day).strftime('%F %H:%M %Z') }
            let!(:released_ticket) {
              Snapshots::ReleasedTicket.create(
                key: 'JIRA-1',
                summary: 'foo',
                description: 'bar',
                versions: [version],
                deploys: [{ 'app' => 'hello_world', 'version' => 'abc', 'deployed_at' => yesterday_str }],
              )
            }

            let(:expected_deploys) {
              [
                { 'app' => 'hello_world', 'version' => 'abc', 'deployed_at' => yesterday_str },
              ]
            }

            it 'updates related tickets with the deploy info' do
              ticket_repo.apply(deploy_event)
              record = store.find_by_key('JIRA-1')
              expect(record.deploys).to match_array(expected_deploys)
            end
          end
        end

        context 'when deploy version is not linked to any ticket' do
          let!(:released_ticket) {
            Snapshots::ReleasedTicket.create(
              key: 'JIRA-1',
              summary: 'foo',
              description: 'bar',
              versions: ['def123'],
              deploys: [{ 'app' => 'hello_world', 'version' => 'def123', 'deployed_at' => time_string }],
            )
          }

          it 'does nothing' do
            ticket_repo.apply(deploy_event)
            expect { ticket_repo.apply(deploy_event) }.to_not change { Snapshots::ReleasedTicket.count }
            expect(released_ticket.deploys).to eq(Snapshots::ReleasedTicket.last.deploys)
          end
        end
      end

      context 'when deploy is not to production' do
        let(:deploy_event) {
          build :deploy_event, environment: 'uat', version: version, created_at: time_string
        }
        let!(:released_ticket) {
          Snapshots::ReleasedTicket
            .create(key: 'JIRA-1', summary: 'foo', description: 'bar',
                    versions: [version, 'def123'],
                    deploys: [{ 'app' => 'hello_world', 'version' => 'def123', 'deployed_at' => time_string }]
                   )
        }
        it 'does nothing' do
          ticket_repo.apply(deploy_event)
          expect { ticket_repo.apply(deploy_event) }.to_not change { Snapshots::ReleasedTicket.count }
          expect(released_ticket.deploys).to eq(Snapshots::ReleasedTicket.last.deploys)
        end
      end
    end

    context 'when Feature Review is for topic branch commit' do
      before do
        commit = instance_double(GitCommit, associated_ids: %w(abc def))
        repository = instance_double(GitRepository)
        repository_loader = instance_double(GitRepositoryLoader)

        allow(GitRepositoryLoader).to receive(:from_rails_config).and_return(repository_loader)
        allow(repository_loader).to receive(:load).and_return(repository)
        allow(repository).to receive(:commit_for_version).with('def').and_return(commit)
      end

      it 'snapshots' do
        jira_event = build(:jira_event, event_attrs.merge(comment_body: feature_review_url(app: 'abc')))
        deploy_event = build(:deploy_event, environment: 'production', version: 'def', created_at: time)

        ticket_repo.apply(jira_event)
        ticket_repo.apply(deploy_event)

        deployed_versions = Snapshots::ReleasedTicket.last.deploys.map { |d| d['version'] }
        expect(deployed_versions).to contain_exactly('def')
      end
    end

    it 'does not apply the event when it is irrelevant' do
      event = build(:uat_event)
      expect { ticket_repo.apply(event) }.not_to change { Snapshots::ReleasedTicket.count }
    end
  end
end
