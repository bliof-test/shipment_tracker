# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Repositories::DeployRepository do
  subject(:repository) { Repositories::DeployRepository.new }

  def apply_deploys(*deploy_events_data)
    deploy_events_data.each do |deploy_event_data|
      deploy_event = create(:deploy_event, deploy_event_data)
      repository.apply(deploy_event.reload)
    end
  end

  def apply_deploy_alert_for(version:, environment:, region:)
    deploy = repository
             .deploys_for_versions([version], environment: environment, region: region)
             .first

    Repositories::DeployAlertRepository.new.apply(
      Events::DeployAlertEvent.new(
        details: { deploy_uuid: deploy.uuid, message: 'Not Good!' },
      ),
    )
  end

  def expand_sha(sha)
    "#{sha}abcabcabcabcabcabcabcabcabcabcabcabcabc"[0..39]
  end

  describe '#table_name' do
    let(:active_record_class) { class_double(Snapshots::Deploy, table_name: 'the_table_name') }

    subject(:repository) { Repositories::DeployRepository.new(active_record_class) }

    it 'delegates to the active record class backing the repository' do
      expect(repository.table_name).to eq('the_table_name')
    end
  end

  describe '#apply' do
    let(:versions) { %w(abc def xyz jkl).map { |sha| expand_sha(sha) } }
    let(:environment) { 'production' }
    let(:defaults) {
      { app_name: 'frontend', server: 'test.com', deployed_by: 'Bob', environment: environment, locale: 'us' }
    }
    let(:expected_attrs) {
      {
        current_deploy: {
          'id' => a_value > 0,
          'uuid' => a_value,
          'app_name' => 'frontend',
          'server' => 'test.com',
          'version' => expand_sha('xyz'),
          'deployed_by' => 'Bob',
          'deployed_at' => '',
          'environment' => environment,
          'region' => 'us',
          'deploy_alert' => nil,
        },
        previous_deploy: nil,
      }
    }

    before do
      allow(DeployAlert).to receive(:auditable?).and_return(true)
    end

    it 'will create a snapshot based on the event' do
      repository.apply(
        build(
          :deploy_event,
          version: expand_sha('xyz'),
          environment: 'production',
          app_name: 'frontend',
          server: 'test.com',
          deployed_by: 'Bob',
          locale: 'us',
          uuid: 'bad85eb9-0713-4da7-8d36-07a8e4b00eab',
        ),
      )

      expect(Snapshots::Deploy.find_by(uuid: 'bad85eb9-0713-4da7-8d36-07a8e4b00eab'))
        .to have_attributes(
          version: expand_sha('xyz'),
          environment: 'production',
          app_name: 'frontend',
          server: 'test.com',
          deployed_by: 'Bob',
          region: 'us',
          uuid: 'bad85eb9-0713-4da7-8d36-07a8e4b00eab',
        )
    end

    it 'schedules a DeployAlertJob' do
      expect(DeployAlertJob).to receive(:perform_later).with(expected_attrs)

      repository.apply(
        build(:deploy_event, defaults.merge(version: expand_sha('xyz'), environment: 'production')),
      )
    end

    context 'when in data maintenance mode' do
      before do
        allow(Rails.configuration).to receive(:data_maintenance_mode).and_return(true)
      end

      it 'does not schedule a DeployAlertJob' do
        expect(DeployAlertJob).not_to receive(:perform_later)

        repository.apply(
          build(:deploy_event, defaults.merge(version: expand_sha('xyz'), environment: 'production')),
        )
      end
    end
  end

  describe '#deploys_for_versions' do
    let(:versions) { %w(abc def xyz jkl).map { |sha| expand_sha(sha) } }
    let(:environment) { 'production' }
    let(:defaults) {
      { app_name: 'frontend', server: 'test.com', deployed_by: 'Bob', environment: environment, locale: 'us' }
    }

    context 'when deploy events exist' do
      it 'returns all deploys for given version, environment and region' do
        apply_deploys(
          defaults.merge(version: expand_sha('xyz'), environment: 'uat'),
          defaults.merge(version: expand_sha('abc')),
          defaults.merge(version: expand_sha('abc'), deployed_by: 'Car'),
          defaults.merge(version: expand_sha('def')),
          defaults.merge(version: expand_sha('ghi')),
          defaults.merge(version: expand_sha('jkl'), locale: 'gb'),
        )

        deploys = repository.deploys_for_versions(versions, environment: environment, region: 'us')

        expect(deploys.map { |deploy|
          deploy.attributes.slice(:version, :deployed_by, :region)
        }).to match_array([
          { version: versions.first, deployed_by: 'Car', region: 'us' },
          { version: versions.second, deployed_by: 'Bob', region: 'us' },
        ])
      end
    end

    context 'when no deploy exists' do
      it 'returns empty' do
        expect(repository.deploys_for_versions(versions, environment: environment, region: 'us')).to be_empty
      end
    end
  end

  describe '#unapproved_production_deploys_for' do
    let(:defaults) { { app_name: 'frontend', deployed_by: 'Bob', locale: 'gb', created_at: Date.parse('01-04-2017') } }

    context 'with no specified time frame' do
      it 'returns all unapproved production deploys for a specified region' do
        apply_deploys(
          defaults.merge(environment: 'uat', version: expand_sha('def')),
          defaults.merge(environment: 'production', version: expand_sha('abc')),
          defaults.merge(environment: 'production', version: expand_sha('ghi')),
          defaults.merge(environment: 'production', version: expand_sha('xyz')),
        )

        apply_deploy_alert_for(version: expand_sha('abc'), environment: 'production', region: 'gb')
        apply_deploy_alert_for(version: expand_sha('ghi'), environment: 'production', region: 'gb')

        deploys = repository.unapproved_production_deploys_for(
          app_name: 'frontend',
          region: 'gb',
        )

        expect(deploys.count).to eq(2)
        expect(deploys.map(&:version)).to match_array([expand_sha('abc'), expand_sha('ghi')])
      end
    end

    context 'with given specified time frame' do
      it 'returns the unapproved production deploys for a specified region within a specified time frame' do
        apply_deploys(
          defaults.merge(environment: 'uat', version: expand_sha('def')),
          defaults.merge(environment: 'production', version: expand_sha('abc')),
          defaults.merge(environment: 'production', version: expand_sha('xyz'), created_at: Date.parse('01-02-2017')),
          defaults.merge(environment: 'production', version: expand_sha('xyz')),
          defaults.merge(environment: 'production', version: expand_sha('xyz'), locale: 'us'),
        )

        apply_deploy_alert_for(version: expand_sha('xyz'), environment: 'production', region: 'gb')

        deploys = repository.unapproved_production_deploys_for(
          app_name: 'frontend',
          region: 'gb',
          from_date: Date.parse('01-03-2017'),
          to_date: Date.parse('01-05-2017'),
        )

        expect(deploys.count).to eq(1)
        expect(deploys.first.region).to eq('gb')
        expect(deploys.first.environment).to eq('production')
        expect(deploys.first.deploy_alert).to eq('Not Good!')
        expect(deploys.first.deployed_at).to eq(Date.parse('01-04-2017'))
      end
    end
  end

  describe '#last_staging_deploy_for_version' do
    let(:version) { expand_sha('abc') }
    let(:defaults) { { app_name: 'frontend', deployed_by: 'Bob', locale: 'de', environment: 'uat' } }

    context 'when no deploy exist' do
      it 'returns nil' do
        expect(repository.last_staging_deploy_for_versions([version])).to be nil
      end
    end

    context 'when no deploys exist for the version under review' do
      it 'returns nil' do
        apply_deploys(
          defaults.merge(server: 'a', environment: 'uat', version: expand_sha('def')),
          defaults.merge(server: 'b', environment: 'uat', version: expand_sha('ghi')),
          defaults.merge(server: 'c', environment: 'production', version: expand_sha('xyz')),
        )

        expect(repository.last_staging_deploy_for_versions([version])).to be nil
      end
    end

    context 'when a deploy exists for the version under review' do
      before do
        apply_deploys(
          defaults.merge(server: 'a', environment: 'uat', version: version),
          defaults.merge(server: 'b', environment: 'uat', version: version),
          defaults.merge(server: 'b', environment: 'uat', version: expand_sha('def')),
          defaults.merge(server: 'c', environment: 'production', version: version),
        )
      end

      it 'returns the latest non-production deploy for the version under review' do
        deploy = repository.last_staging_deploy_for_versions([version])

        expect(deploy.version).to eq(version)
        expect(deploy.server).to eq('b')
        expect(deploy.region).to eq('de')
      end

      it 'looks for any non-production environments' do
        apply_deploys(defaults.merge(server: 'c', environment: 'uat', version: version))

        deploy = repository.last_staging_deploy_for_versions([version])
        expect(deploy.version).to eq(version)
        expect(deploy.server).to eq('c')
        expect(deploy.region).to eq('de')
      end
    end
  end

  describe '#second_last_production_deploy' do
    let(:defaults) {
      {
        server: 'a',
        app_name: 'frontend',
        deployed_by: 'Bob',
        locale: 'gb',
        environment: 'production',
      }
    }

    context 'when no deploy exist' do
      it 'returns nil' do
        expect(repository.second_last_production_deploy('frontend', 'gb')).to be nil
      end
    end

    context 'when a deploy exists for the app and region' do
      it 'returns the second latest production deploy for the app_name and region' do
        apply_deploys(
          defaults.merge(app_name: 'backend', version: expand_sha('ccc')),
          defaults.merge(version: expand_sha('bbb')),
          defaults.merge(app_name: 'backend', version: expand_sha('def'), locale: 'us'),
          defaults.merge(app_name: 'backend', version: expand_sha('eee')),
          defaults.merge(version: expand_sha('ccc')),
        )

        deploy = repository.second_last_production_deploy('backend', 'gb')

        expect(deploy.version).to eq expand_sha('ccc')
        expect(deploy.region).to eq 'gb'
      end
    end
  end
end
