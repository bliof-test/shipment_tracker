# frozen_string_literal: true
require 'events/deploy_event'
require 'snapshots/deploy'
require 'deploy'
require 'deploy_alert_job'

module Repositories
  class DeployRepository < Base
    def initialize(store = Snapshots::Deploy)
      @store = store
    end

    def deploys_for(apps: nil, server:, at: nil)
      deploys(apps, server, at)
    end

    def unapproved_production_deploys_for(app_name:, region:, from_date: nil, to_date: nil)
      time_period_query = if from_date.present? && to_date.present?
                            store.arel_table['deployed_at'].between(from_date.beginning_of_day..to_date.end_of_day)
                          end
      store
        .where(time_period_query)
        .where(app_name: app_name, environment: 'production', region: region)
        .where.not(deploy_alert: nil).map { |deploy_record|
          Deploy.new(deploy_record.attributes)
        }
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

    def last_staging_deploy_for_versions(versions)
      last_matching_non_prod_deploy = store.where.not(environment: 'production').where(version: versions).last
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
        audit_deploy(current_deploy)
      end
    rescue GitRepositoryLoader::NotFound => error
      Honeybadger.notify(
        error,
        context: {
          event_id: event.id,
          app_name: event.app_name,
          deployer: event.deployed_by,
          deploy_time: event.created_at,
        },
      )
    end

    private

    def create_deploy_snapshot!(event)
      store.create!(
        app_name: event.app_name,
        server: event.server,
        region: event.locale,
        environment: event.environment,
        version: event.version,
        uuid: event.uuid,
        deployed_by: event.deployed_by,
        deployed_at: event.created_at,
      )
    end

    def audit_deploy(current_deploy)
      previous_deploy = second_last_production_deploy(current_deploy.app_name, current_deploy.region)

      DeployAlertJob.perform_later(
        current_deploy: data_for_deploy(current_deploy),
        previous_deploy: data_for_deploy(previous_deploy),
      )
    end

    def data_for_deploy(deploy)
      return unless deploy

      data = deploy.attributes
      data['deployed_at'] = data['deployed_at'].to_s

      data
    end

    def deploys(apps, server, at)
      query = store.select('DISTINCT ON (server, app_name) *').where(server: server)
      query = query.where(store.arel_table['deployed_at'].lteq(at)) if at
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
