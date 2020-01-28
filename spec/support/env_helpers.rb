# frozen_string_literal: true

module Support
  module EnvHelpers
    def with_env(envs = {})
      original_envs = ENV.select { |k, _| envs.key? k }
      envs.each { |k, v| ENV[k] = v }

      yield
    ensure
      envs.each_key { |k| ENV.delete k }
      original_envs.each { |k, v| ENV[k] = v }
    end
  end
end
