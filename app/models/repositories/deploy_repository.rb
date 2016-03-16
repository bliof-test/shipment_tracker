require 'events/deploy_event'
require 'snapshots/deploy'
require 'deploy'
require 'deploy_alert_job'

module Repositories
  class DeployRepository
    def initialize(store = Snapshots::Deploy)
      @store = store
    end

    delegate :table_name, to: :store

    def deploys_for(apps: nil, server:, at: nil)
      deploys(apps, server, at)
    end

    def deploys_for_versions(versions, environment:, region:)
      query = store.select('DISTINCT ON (version) *')
      query = query.where(store.arel_table['version'].in(versions))
      query = query.where(environment: environment)
      query = query.where(region: region)
      query.order('version, id DESC').map { |deploy_record|
        Deploy.new(deploy_record.attributes)
      }
    end

    def last_staging_deploy_for_version(version)
      last_matching_non_prod_deploy = store.where.not(environment: 'production').where(version: version).last
      Deploy.new(last_matching_non_prod_deploy.attributes) if last_matching_non_prod_deploy
    end

    def second_last_production_deploy(app_name, region)
      store.where(app_name: app_name, environment: 'production', region: region)
           .order(id: 'desc')
           .limit(1)
           .offset(1)
           .first
    end

    def apply(event)
      return unless event.is_a?(Events::DeployEvent)
      current_deploy = create_deploy_snapshot!(event)

      if DeployAlert.auditable?(current_deploy) && !Rails.configuration.data_maintenance_mode
        previous_deploy = second_last_production_deploy(current_deploy.app_name, current_deploy.region)
        audit_deploy(current_deploy: current_deploy.attributes, previous_deploy: previous_deploy&.attributes)
      end
    end

    private

    attr_reader :store

    def create_deploy_snapshot!(event)
      store.create!(
        app_name: event.app_name,
        server: event.server,
        region: event.locale,
        environment: event.environment,
        version: event.version,
        deployed_by: event.deployed_by,
        event_created_at: event.created_at,
      )
    end

    def audit_deploy(deploys_attrs)
      deploy_time_to_s(deploys_attrs[:current_deploy])
      deploy_time_to_s(deploys_attrs[:previous_deploy])
      DeployAlertJob.perform_later(deploys_attrs)
    end

    def deploy_time_to_s(deploy_attrs)
      deploy_attrs['event_created_at'] = deploy_attrs['event_created_at'].to_s if deploy_attrs
    end

    def deploys(apps, server, at)
      query = store.select('DISTINCT ON (server, app_name) *').where(server: server)
      query = query.where(store.arel_table['event_created_at'].lteq(at)) if at
      query = query.where(store.arel_table['app_name'].in(apps.keys)) if apps
      query.order('server, app_name, id DESC').map { |deploy_record|
        build_deploy(deploy_record.attributes, apps)
      }
    end

    def build_deploy(deploy_attr, apps)
      correct = apps.present? && deploy_attr.fetch('version') == apps[deploy_attr.fetch('app_name')]
      Deploy.new(deploy_attr.merge(correct: correct))
    end
  end
end
