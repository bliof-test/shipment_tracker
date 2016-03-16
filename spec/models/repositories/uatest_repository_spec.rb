require 'rails_helper'

RSpec.describe Repositories::UatestRepository do
  let(:deploy_repository) { Repositories::DeployRepository.new }

  subject(:repository) { Repositories::UatestRepository.new(deploy_repository: deploy_repository) }

  describe '#table_name' do
    let(:active_record_class) { class_double(Snapshots::Uatest, table_name: 'the_table_name') }

    subject(:repository) { Repositories::UatestRepository.new(active_record_class) }

    it 'delegates to the active record class backing the repository' do
      expect(repository.table_name).to eq('the_table_name')
    end
  end

  describe '#uatest_for' do
    let(:server) { 'uat.example.com' }
    let(:defaults) { { success: true, test_suite_version: '111', server: server } }

    it 'projects last UaTest' do
      [
        build(:deploy_event, server: server, version: 'abc', app_name: 'frontend'),
        build(:uat_event, defaults),
      ].each do |event|
        deploy_repository.apply(event)
        repository.apply(event)
      end

      result = repository.uatest_for(versions: ['abc'], server: server)
      expect(result).to eq(Uatest.new(defaults))

      repository.apply(build(:uat_event, defaults.merge(test_suite_version: '999')))

      result = repository.uatest_for(versions: ['abc'], server: server)
      expect(result).to eq(Uatest.new(defaults.merge(test_suite_version: '999')))
    end

    context 'when the server matches' do
      context 'when the app versions match' do
        before do
          deploy_repository.apply(build(:deploy_event, server: server, app_name: 'frontend', version: 'old'))
          deploy_repository.apply(build(:deploy_event, server: server, app_name: 'frontend', version: 'abc'))
          deploy_repository.apply(build(:deploy_event, server: server, app_name: 'backend', version: 'def'))
        end

        it 'returns the relevant User Acceptance Tests details' do
          repository.apply(build(:uat_event, test_suite_version: 'xyz', success: true, server: server))
          repository.apply(build(:jira_event))
          result = repository.uatest_for(versions: %w(abc def), server: server)
          expect(result).to eq(Uatest.new(success: true, test_suite_version: 'xyz'))

          repository.apply(build(:uat_event, test_suite_version: 'xyz', success: false, server: server))
          result = repository.uatest_for(versions: %w(abc def), server: server)
          expect(result).to eq(Uatest.new(success: false, test_suite_version: 'xyz'))
        end
      end

      context 'when some of the versions match' do
        before do
          [
            build(:deploy_event, server: server, app_name: 'frontend', version: 'abc'),
            build(:deploy_event, server: server, app_name: 'backend', version: 'not_def'),
          ].each do |event|
            deploy_repository.apply(event)
          end
        end

        it 'ignores the UAT event' do
          uat_event = build(:uat_event, server: server)

          repository.apply(uat_event)

          expect(repository.uatest_for(versions: %w(abc def), server: server)).to be nil
        end
      end

      context 'when none of the versions match' do
        before do
          [
            build(:deploy_event, server: server, app_name: 'frontend', version: 'not_abc'),
            build(:deploy_event, server: server, app_name: 'backend', version: 'not_def'),
          ].each do |event|
            deploy_repository.apply(event)
          end
        end

        it 'ignores the UAT event' do
          uat_event = build(:uat_event, server: server)

          repository.apply(uat_event)

          expect(repository.uatest_for(versions: %w(abc def), server: server)).to be nil
        end
      end
    end

    context 'when the server does not match' do
      before do
        deploy_repository.apply(build(:deploy_event, server: server, app_name: 'frontend', version: 'abc'))
      end

      it 'ignores the UAT event' do
        repository.apply(build(:uat_event, server: 'other.server'))
        expect(repository.uatest_for(versions: ['abc'], server: server)).to be nil
      end
    end

    context 'when we receive deploy events for different servers' do
      it 'does not affect the result' do
        [
          build(:deploy_event, server: server, app_name: 'frontend', version: 'abc'),
          build(:deploy_event, server: 'other.server', app_name: 'frontend', version: 'zzz'),
        ].each do |event|
          deploy_repository.apply(event)
        end

        repository.apply(build(:uat_event, server: server))
        expect(repository.uatest_for(versions: ['abc'], server: server)).to be_present
      end
    end

    context 'with at specified' do
      it 'returns the state at that moment' do
        # usec reset is required as the precision for the database column is not as great as the Time class,
        # without it, tests would fail on CI build.
        times = [2.hours.ago, 1.hour.ago].map { |t| t.change(usec: 0) }

        deploy_repository.apply(
          build(:deploy_event, server: server, version: 'abc', app_name: 'frontend', created_at: times[0]),
        )

        [
          build(:uat_event, test_suite_version: '1', server: server, success: false, created_at: times[0]),
          build(:uat_event, test_suite_version: '1', server: 'other', success: true, created_at: times[0]),
          build(:uat_event, test_suite_version: '2', server: server, success: true, created_at: times[1]),
        ].each do |event|
          repository.apply(event)
        end

        result = repository.uatest_for(versions: ['abc'], server: server, at: times[0])
        expect(result).to eq(Uatest.new(success: false, test_suite_version: '1'))
      end
    end
  end
end
