# frozen_string_literal: true

# rubocop:disable all

require 'rack/utils'

# We are going to monkey patch the commonlogger that rack uses in order to
# filter out any 'token' parameters found within a http request.
#
# The common logger can be found here:
# https://github.com/rack/rack/blob/master/lib/rack/common_logger.rb
module Rack
  class CommonLogger
    # # Common Log Format: http://httpd.apache.org/docs/1.3/logs.html#common
    # #
    # #   lilith.local - - [07/Aug/2006 23:58:02 -0400] "GET / HTTP/1.1" 500 -
    # #
    # #   %{%s - %s [%s] "%s %s%s %s" %d %s\n} %
    # #   FORMAT = %{%s - %s [%s] "%s %s%s %s" %d %s %0.4f\n}

    def initialize(app, logger = nil)
      @app = app
      @logger = logger
    end

    def call(env)
      began_at = Time.now.to_f
      status, header, body = @app.call(env)
      header = Utils::HeaderHash.new(header)
      body = BodyProxy.new(body) { log(env, status, header, began_at) }
      [status, header, body]
    end

    private

    def filter_param(s)
        filter = /token=([^&]*)/
        s.gsub(filter, 'token=[FILTERED]')
    end

    def log(env, status, header, began_at)
      length = extract_content_length(header)

      # begin filtering out tokens
      filtered_path = filter_param(env['PATH_INFO'])
      filtered_query = filter_param(env['QUERY_STRING'])

      # use filtered version of tokens
      msg = FORMAT % [
        env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
        env['REMOTE_USER'] || "-",
        Time.now.strftime("%d/%b/%Y:%H:%M:%S %z"),
        env['REQUEST_METHOD'],
        filtered_path,
        filtered_query.empty? ? "" : "?#{filtered_query}",
        env['HTTP_VERSION'],
        status.to_s[0..3],
        length,
        (Time.now.to_f - began_at) ]

      logger = @logger || env['RACK_ERRORS']
      # Standard library logger doesn't support write but it supports << which actually
      # calls to write on the log device without formatting
      if logger.respond_to?(:write)
        logger.write(msg)
      else
        logger << msg
      end
    end

    def extract_content_length(headers)
      value = headers['CONTENT_LENGTH']
      !value || value.to_s == '0' ? '-' : value
    end
  end
end
