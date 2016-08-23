# frozen_string_literal: true
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
    let(:result) { double }

    before do
      allow(store).to receive(:search_for).and_return(result)
      allow(result).to receive(:limit).and_return([ticket])
    end

    it 'delegates search to store' do
      ticket_repo.tickets_for_query(query_text: query, versions: [])
      expect(store).to have_received(:search_for).with(query)
    end

    it 'returns Ticket objects' do
      tickets = ticket_repo.tickets_for_query(query_text: query, versions: [])
      expect(tickets.first).to be_a(ReleasedTicket)
    end

    context 'when no tickets found' do
      before do
        allow(result).to receive(:limit).and_return([])
      end

      it 'returns empty array' do
        tickets = ticket_repo.tickets_for_query(query_text: query, versions: [])
        expect(tickets).to be_empty
      end
    end

    context 'when specifying a per_page amount' do
      let(:specified_amount) { 3 }

      before do
        stub_const('ShipmentTracker::NUMBER_OF_TICKETS_TO_DISPLAY', specified_amount)
        allow(result).to receive(:limit).and_return([ticket, ticket, ticket])
      end

      it 'returns results limited to the amount requested' do
        tickets = ticket_repo.tickets_for_query(query_text: query, versions: [])

        expect(tickets.count).to eq(specified_amount)
        expect(result).to have_received(:limit).with(specified_amount)
      end
    end

    describe 'filter by date' do
      let(:store) { Snapshots::ReleasedTicket }
      let(:time) { Time.zone.today }
      subject(:ticket_repo) { Repositories::ReleasedTicketRepository.new }
      let!(:deployed_tickets) {
        [
          store.create(key: 'ENG-1', deploys: [{ app: 'app1', deployed_at: time - 3.weeks },
                                               { app: 'app1', deployed_at: time - 1.week }].to_json),
          store.create(key: 'ENG-2', deploys: [{ app: 'app1', deployed_at: time - 1.week },
                                               { app: 'app1', deployed_at: time }].to_json),
          store.create(key: 'ENG-3', deploys: [{ app: 'app1', deployed_at: time - 4.weeks },
                                               { app: 'app1', deployed_at: time - 3.weeks }].to_json),
        ].map { |record| ReleasedTicketDecorator.new(ReleasedTicket.new(record.attributes)) }
      }

      context "when 'from' date is selected" do
        let(:query) {
          {
            query_text: '',
            versions: [],
            from_date: time - 2.weeks,
            to_date: nil,
          }
        }

        it "returns tickets deployed since 'from' date" do
          tickets = ticket_repo.tickets_for_query(query)
          expect(tickets).to match_array(deployed_tickets[0..1])
        end
      end

      context "when 'to' date is selected" do
        let(:query) {
          {
            query_text: '',
            versions: [],
            from_date: nil,
            to_date: time - 2.weeks,
          }
        }
        it "returns tickets first deployed before 'to' date" do
          tickets = ticket_repo.tickets_for_query(query)
          expect(tickets).to match_array([deployed_tickets.first, deployed_tickets.last])
        end
      end

      context "when 'from' and 'to' dates are selected" do
        let!(:deployed_tickets) {
          [
            store.create(key: 'ENG-1', deploys: [{ app: 'app1', deployed_at: time - 3.weeks }].to_json),
            store.create(key: 'ENG-2', deploys: [{ app: 'app2', deployed_at: time - 5.weeks },
                                                 { app: 'app2', deployed_at: time }].to_json),
            store.create(key: 'ENG-3', deploys: [{ app: 'app3', deployed_at: time - 5.weeks },
                                                 { app: 'app3', deployed_at: time - 3.weeks }].to_json),
            store.create(key: 'ENG-4', deploys: [{ app: 'app4', deployed_at: time - 3.weeks },
                                                 { app: 'app4', deployed_at: time }].to_json),
            store.create(key: 'ENG-5', deploys: [{ app: 'app5', deployed_at: time - 6.weeks },
                                                 { app: 'app5', deployed_at: time - 5.weeks }].to_json),
            store.create(key: 'ENG-6', deploys: [{ app: 'app6', deployed_at: time - 1.week },
                                                 { app: 'app6', deployed_at: time }].to_json),
          ].map { |record| ReleasedTicketDecorator.new(ReleasedTicket.new(record.attributes)) }
        }

        let(:query) {
          {
            query_text: '',
            versions: [],
            from_date: time - 4.weeks,
            to_date: time - 2.weeks,
          }
        }
        it "returns tickets deployed between 'from' and 'to' dates" do
          tickets = ticket_repo.tickets_for_query(query)
          expect(tickets).to match_array([deployed_tickets[0], deployed_tickets[2], deployed_tickets[3]])
        end
      end
    end
  end

  describe '#apply' do
    let(:store) { Snapshots::ReleasedTicket }
    let(:time) { Time.current.change(usec: 0) }
    let(:repository) { instance_double(GitRepository) }
    let(:commit_version) { 'abc' }
    let(:event_attrs) {
      {
        'key' => 'JIRA-123',
        'summary' => 'some summary',
        'description' => 'some description',
      }
    }

    before do
      commit = instance_double(GitCommit, id: commit_version, associated_ids: %w(abc def))
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
        build(:deploy_event, environment: 'production', version: version, created_at: second_time)
      }
      let(:version) { 'abc' }
      let(:time_string) { time.strftime('%F %H:%M %Z') }
      let(:second_time) { time + 1.week }
      let(:second_time_string) { second_time.strftime('%F %H:%M %Z') }
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
                'version' => 'def',
                'deployed_at' => time_string,
                'deployed_by' => 'frank@example.com',
                'github_url' => gurl,
                'region' => 'gb',
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
                'deployed_at' => second_time_string,
                'deployed_by' => 'frank@example.com',
                'github_url' => gurl,
                'region' => 'us',
              },
              {
                'app' => 'hello_world',
                'version' => 'def',
                'deployed_at' => time_string,
                'deployed_by' => 'frank@example.com',
                'github_url' => gurl,
                'region' => 'gb',
              },
            ]
          }

          it 'updates related tickets with the deploy info' do
            ticket_repo.apply(deploy_event)
            record = store.find_by_key('JIRA-1')
            expect(record.deploys).to match_array(expected_deploys)
          end

          context 'when no previous deploys' do
            let!(:released_ticket) {
              Snapshots::ReleasedTicket.create(
                key: 'JIRA-1',
                summary: 'foo',
                description: 'bar',
                versions: [version],
                deploys: [],
              )
            }

            let(:expected_deploys) {
              [
                {
                  'app' => 'hello_world',
                  'version' => 'abc',
                  'deployed_at' => second_time_string,
                  'deployed_by' => 'frank@example.com',
                  'github_url' => gurl,
                  'region' => 'us',
                },
              ]
            }

            it 'sets the first and last deployed at time' do
              ticket_repo.apply(deploy_event)
              record = store.find_by_key('JIRA-1')
              expect(record.deploys).to match_array(expected_deploys)
            end
          end

          context 'when the version was deployed already' do
            let(:yesterday_str) { (time - 1.day).strftime('%F %H:%M %Z') }
            let!(:released_ticket) {
              Snapshots::ReleasedTicket.create(
                key: 'JIRA-1',
                summary: 'foo',
                description: 'bar',
                versions: [version],
                deploys: [{
                  'app' => 'hello_world',
                  'version' => 'abc',
                  'deployed_at' => yesterday_str,
                  'deployed_by' => 'frank@example.com',
                  'region' => 'us',
                }],
              )
            }

            let(:expected_deploys) {
              [
                {
                  'app' => 'hello_world',
                  'version' => 'abc',
                  'deployed_at' => yesterday_str,
                  'deployed_by' => 'frank@example.com',
                  'region' => 'us',
                },
              ]
            }

            it 'updates related tickets with the deploy info' do
              ticket_repo.apply(deploy_event)
              record = store.find_by_key('JIRA-1')
              expect(record.deploys).to match_array(expected_deploys)
            end
          end

          context 'when deploying to different regons' do
            let(:deploy_event_gb) {
              build(:deploy_event, environment: 'production', version: version, created_at: time_string,
                                   locale: 'gb'
                   )
            }
            let(:deploy_event_us) {
              build(:deploy_event, environment: 'production', version: version, created_at: time_string,
                                   locale: 'us'
                   )
            }
            let!(:released_ticket) {
              Snapshots::ReleasedTicket.create(
                key: 'JIRA-1',
                summary: 'foo',
                description: 'bar',
                versions: [version],
                deploys: [],
              )
            }

            let(:expected_deploys) {
              [
                {
                  'app' => 'hello_world',
                  'version' => 'abc',
                  'deployed_at' => time_string,
                  'deployed_by' => 'frank@example.com',
                  'github_url' => gurl,
                  'region' => 'us',
                },
                {
                  'app' => 'hello_world',
                  'version' => 'abc',
                  'deployed_at' => time_string,
                  'deployed_by' => 'frank@example.com',
                  'github_url' => gurl,
                  'region' => 'gb',
                },
              ]
            }

            it 'updates related tickets with the deploy info' do
              ticket_repo.apply(deploy_event_gb)
              ticket_repo.apply(deploy_event_us)
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
              deploys: [{
                'app' => 'hello_world',
                'version' => 'def123',
                'deployed_at' => time_string,
                'deployed_by' => 'frank@example.com',
                'region' => 'gb',
              }],
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
      let(:commit_version) { 'def' }
      it 'performs snapshotting' do
        jira_event = build(:jira_event, event_attrs.merge(comment_body: feature_review_url(app: 'abc')))
        deploy_event = build(:deploy_event, environment: 'production', version: 'def', created_at: time)

        ticket_repo.apply(jira_event)
        ticket_repo.apply(deploy_event)

        deployed_versions = Snapshots::ReleasedTicket.last.deploys.map { |d| d['version'] }
        expect(deployed_versions).to contain_exactly('def')
      end
    end

    context 'when deploy event does not contain a version' do
      before do
        allow(repository).to receive(:commit_for_version).with(nil).and_raise(TypeError)
      end

      it 'does not snapshot' do
        jira_event = build(:jira_event, event_attrs.merge(comment_body: feature_review_url(app: 'abc')))
        deploy_event = build(:deploy_event, environment: 'production', version: nil, created_at: time)

        ticket_repo.apply(jira_event)

        expect { ticket_repo.apply(deploy_event) }.not_to change { Snapshots::ReleasedTicket.count }
      end
    end

    context 'when deploy event contains invalid commit version' do
      let(:previous_deploy) { instance_double(Deploy, version: 'bcd') }
      before do
        allow(Snapshots::Deploy).to receive_message_chain(:where, :where, :order, :limit, :first)
          .and_return(previous_deploy)
        allow(repository).to receive(:commits_between).and_raise(GitRepository::CommitNotValid)
      end

      it 'does not snapshot' do
        jira_event = build(:jira_event, event_attrs.merge(comment_body: feature_review_url(app: 'abc')))
        deploy_event = build(:deploy_event, environment: 'production', version: 'invalid', created_at: time)

        ticket_repo.apply(jira_event)

        expect { ticket_repo.apply(deploy_event) }.not_to change { Snapshots::ReleasedTicket.count }
      end
    end

    context 'when deploy event commit version can not be found' do
      let(:previous_deploy) { instance_double(Deploy, version: 'bcd') }
      before do
        allow(Snapshots::Deploy).to receive_message_chain(:where, :where, :order, :limit, :first)
          .and_return(previous_deploy)
        allow(repository).to receive(:commits_between).and_raise(GitRepository::CommitNotFound)
      end

      it 'does not snapshot' do
        jira_event = build(:jira_event, event_attrs.merge(comment_body: feature_review_url(app: 'abc')))
        deploy_event = build(:deploy_event, environment: 'production', version: 'invalid', created_at: time)

        ticket_repo.apply(jira_event)

        expect { ticket_repo.apply(deploy_event) }.not_to change { Snapshots::ReleasedTicket.count }
      end
    end

    it 'does not apply the event when it is irrelevant' do
      event = build(:uat_event)
      expect { ticket_repo.apply(event) }.not_to change { Snapshots::ReleasedTicket.count }
    end
  end
end
