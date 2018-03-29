# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Repositories::BuildRepository do
  subject(:repository) { Repositories::BuildRepository.new }

  describe '#table_name' do
    let(:active_record_class) { class_double(Snapshots::Build, table_name: 'the_table_name') }

    subject(:repository) { Repositories::BuildRepository.new(active_record_class) }

    it 'delegates to the active record class backing the repository' do
      expect(repository.table_name).to eq('the_table_name')
    end
  end

  describe '#unit_test_results_for' do
    let(:apps) { { 'frontend' => 'abc' } }

    it 'projects last build' do
      repository.apply(build(:jenkins_event, success?: false, app_name: 'frontend', version: 'abc'))
      expect(repository.unit_test_results_for(apps: apps)).to eq(
        'frontend' => FactoryBot.build(
          :unit_test_build,
          source: 'Jenkins',
          url: 'http://example.com',
          success: false,
          app_name: 'frontend',
          version: 'abc',
        ),
      )

      repository.apply(build(:jenkins_event, success?: true, app_name: 'frontend', version: 'abc'))
      expect(repository.unit_test_results_for(apps: apps)).to eq(
        'frontend' => FactoryBot.build(
          :unit_test_build,
          source: 'Jenkins',
          url: 'http://example.com',
          success: true,
          app_name: 'frontend',
          version: 'abc',
        ),
      )
    end

    context 'with multiple apps' do
      let(:apps) { { 'frontend' => 'abc', 'backend' => 'def', 'other' => 'xyz' } }

      it 'returns multiple builds' do
        repository.apply(build(:jenkins_event, success?: false, app_name: 'frontend', version: 'abc'))
        repository.apply(build(:circle_ci_event, success?: true, app_name: 'backend', version: 'def'))

        expect(repository.unit_test_results_for(apps: apps)).to eq(
          'frontend' => FactoryBot.build(
            :unit_test_build,
            source: 'Jenkins',
            url: 'http://example.com',
            success: false,
            app_name: 'frontend',
            version: 'abc',
          ),
          'backend' => FactoryBot.build(
            :unit_test_build,
            source: 'CircleCi',
            url: 'http://example.com',
            success: true,
            app_name: 'backend',
            version: 'def',
          ),
          'other' => FactoryBot.build(:unit_test_build),
        )
      end
    end

    context 'with at specified' do
      def create_event(options = {})
        default = {
          app_name: 'abc',
          build_type: 'unit',
          version: 'ab91d954a51ddc74e29e7582d9a2efe8bb6d480f',
          success?: true,
          build_url: 'http://example.com',
          created_at: Time.now,
        }

        build(:circle_ci_event, default.merge(options))
      end

      it 'returns the state at that moment' do
        repository.apply(create_event(success?: true, app_name: 'app1', version: 'abc', created_at: 3.hours.ago))
        repository.apply(create_event(success?: true, app_name: 'app2', version: 'def', created_at: 2.hours.ago))
        repository.apply(create_event(success?: false, app_name: 'app1', version: 'ghi', created_at: Time.current))
        repository.apply(create_event(success?: false, app_name: 'app2', version: 'jkl', created_at: 1.hour.ago))

        result = repository.unit_test_results_for(
          apps: {
            'app1' => 'abc',
            'app2' => 'def',
          },
          at: 2.hours.ago,
        )

        expect(result).to eq(
          'app1' => FactoryBot.build(
            :unit_test_build,
            source: 'CircleCi',
            url: 'http://example.com',
            success: true,
            app_name: 'app1',
            version: 'abc',
          ),
          'app2' => FactoryBot.build(
            :unit_test_build,
            source: 'CircleCi',
            url: 'http://example.com',
            success: true,
            app_name: 'app2',
            version: 'def',
          ),
        )
      end
    end
  end

  describe '#integration_test_results_for' do
    def create_event(build_type = :jenkins_event, options = {})
      default = {
        app_name: 'abc',
        build_type: 'integration',
        version: 'ab91d954a51ddc74e29e7582d9a2efe8bb6d480f',
        success?: true,
        build_url: 'http://example.com',
        created_at: Time.now,
      }

      build(build_type, default.merge(options))
    end

    let(:apps) { { 'frontend' => 'abc' } }

    it 'projects last build' do
      repository.apply(create_event(:jenkins_event, success?: false, app_name: 'frontend', version: 'abc'))
      expect(repository.integration_test_results_for(apps: apps)).to eq(
        'frontend' => FactoryBot.build(
          :integration_test_build,
          source: 'Jenkins',
          url: 'http://example.com',
          success: false,
          app_name: 'frontend',
          version: 'abc',
        ),
      )

      repository.apply(create_event(:jenkins_event, success?: true, app_name: 'frontend', version: 'abc'))
      expect(repository.integration_test_results_for(apps: apps)).to eq(
        'frontend' => FactoryBot.build(
          :integration_test_build,
          source: 'Jenkins',
          url: 'http://example.com',
          success: true,
          app_name: 'frontend',
          version: 'abc',
        ),
      )
    end

    context 'with multiple apps' do
      let(:apps) { { 'frontend' => 'abc', 'backend' => 'def', 'other' => 'xyz' } }

      it 'returns multiple builds' do
        repository.apply(create_event(:jenkins_event, success?: false, app_name: 'frontend', version: 'abc'))
        repository.apply(create_event(:circle_ci_event, success?: true, app_name: 'backend', version: 'def'))

        expect(repository.integration_test_results_for(apps: apps)).to eq(
          'frontend' => FactoryBot.build(
            :integration_test_build,
            source: 'Jenkins',
            url: 'http://example.com',
            success: false,
            app_name: 'frontend',
            version: 'abc',
          ),
          'backend' => FactoryBot.build(
            :integration_test_build,
            source: 'CircleCi',
            url: 'http://example.com',
            success: true,
            app_name: 'backend',
            version: 'def',
          ),
          'other' => FactoryBot.build(:integration_test_build),
        )
      end
    end

    context 'with at specified' do
      it 'returns the state at that moment' do
        repository.apply(create_event(:circle_ci_event, app_name: 'app1', version: 'abc', created_at: 3.hours.ago))
        repository.apply(create_event(:circle_ci_event, app_name: 'app2', version: 'def', created_at: 2.hours.ago))
        repository.apply(create_event(:circle_ci_event, app_name: 'app1', version: 'ghi', created_at: Time.current))
        repository.apply(create_event(:circle_ci_event, app_name: 'app2', version: 'jkl', created_at: 1.hour.ago))

        result = repository.integration_test_results_for(
          apps: {
            'app1' => 'abc',
            'app2' => 'def',
          },
          at: 2.hours.ago,
        )

        expect(result).to eq(
          'app1' => FactoryBot.build(
            :integration_test_build,
            source: 'CircleCi',
            url: 'http://example.com',
            success: true,
            app_name: 'app1',
            version: 'abc',
          ),
          'app2' => FactoryBot.build(
            :integration_test_build,
            source: 'CircleCi',
            url: 'http://example.com',
            success: true,
            app_name: 'app2',
            version: 'def',
          ),
        )
      end
    end
  end
end
