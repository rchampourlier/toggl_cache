# frozen_string_literal: true
require "logger"

module TogglAPI

  Error = Class.new(StandardError)

  # Superclass for API clients.
  class BaseClient
    DEFAULT_USER_AGENT = "TogglAPI"
    attr_reader :api_token, :logger

    # Returns a new instance of the client, configured with
    # the specified parameters.
    #
    # @param api_token [String] Toggl API token, for authentication
    # @param user_agent [String] defaults to "TogglCache"
    # @param logger [Logger] used to log message (defaults to a logger
    #   to STDOUT at info level)
    #
    def initialize(api_token: default_api_token, user_agent: default_user_agent, logger: default_logger)
      raise "Missing api_token" if api_token.nil? || api_token.empty?
      @api_token = api_token
      @user_agent = user_agent
      @logger = logger
    end

    def default_api_token
      ENV["TOGGL_API_TOKEN"]
    end

    def default_user_agent
      DEFAULT_USER_AGENT
    end

    def default_logger
      logger = ::Logger.new(STDOUT)
      logger.level = ::Logger::FATAL
      logger
    end

    def credentials
      {
        username: @api_token,
        password: "api_token"
      }
    end

    def default_headers
      {
        "Content-Type" => "application/json"
      }
    end
  end
end
