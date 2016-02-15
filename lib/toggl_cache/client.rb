require 'uri'
require 'active_support/all'
require 'httparty'

module TogglCache

  # The Toggl API Client
  class Client
    attr_reader :logger

    API_URL = 'https://toggl.com/reports/api/v2/'
    API_SUFFIX_DETAILS = 'details'
    API_SUFFIX_SUMMARY = 'summary'
    API_PORT = 443
    DEFAULT_USER_AGENT = 'TogglCache'

    # Returns a new instance of the client, configured with
    # the specified parameters.
    #
    # @param api_token [String] Toggl API token, for authentication
    # @param user_agent [String] defaults to "TogglCache"
    # @param logger [Logger] used to log message (defaults to a logger
    #   to STDOUT at info level)
    #
    def initialize(api_token:, user_agent: DEFAULT_USER_AGENT, logger: nil)
      fail 'Missing api_token' if api_token.blank?
      @api_token = api_token
      @user_agent = user_agent
      @logger = logger || default_logger
    end

    # @param options [Hash]: Toggl API options
    #   - date_since
    #   - date_until
    #   - workspace_id
    #   - ... more options available, see Toggl API for details
    def fetch_reports_multiple_pages(options)
      page = 1
      all_results = []
      loop do
        results = fetch_reports_details(
          options.merge(page: page)
        )['data']

        all_results += results
        page += 1
        break if results.empty?
      end
      all_results
    end

    private

    def fetch_reports_details(options)
      fetch_reports_raw(API_URL + API_SUFFIX_DETAILS, options)
    end

    def self.fetch_reports_summary(options)
      fetch_reports_raw(API_URL + API_SUFFIX_SUMMARY, options)
    end

    # @param url [String]
    # @param options [Hash]: Toggl API options
    def fetch_reports_raw(url, options)
      logger.info "Fetching Toggl reports for options #{options}"

      headers = {
        'Content-Type' => 'application/json'
      }

      params = {
        user_agent: @user_agent,
      }.merge(options)

      credentials = {
        username: @api_token,
        password: 'api_token'
      }

      response = HTTParty.get(
        url,
        headers: headers,
        query: params,
        basic_auth: credentials
      )

      begin
        if response.code == 200 || response.code == 201
          JSON.parse(response.body)
        else
          logger.error "Error (response code #{response.code}, content #{response.body})"
        end
      rescue => e
        # TODO: fix this too large rescue
        logger.error "Exception (#{e})"
      end
    end

    def default_logger
      logger = ::Logger.new(STDOUT)
      logger.level = ::Logger::FATAL
      logger
    end
  end
end
