# frozen_string_literal: true
require "uri"
require "httparty"
require "toggl_api/base_client"

module TogglAPI

  # The Toggl API Client
  class ReportsClient < BaseClient
    API_URL = "https://toggl.com/reports/api/v2"

    # @param params [Hash]: Toggl API params
    #   - since
    #   - until
    #   - workspace_id
    #   - ... more params available, see Toggl API documentation for details
    def fetch_reports(params, &block)
      raise "Must give a block" unless block_given?
      page = 1
      current_total = 0
      loop do
        results_raw = fetch_reports_details_raw(
          params.merge(page: page)
        )
        yield(results_raw["data"])

        current_total += results_raw["data"].count
        break if current_total == results_raw["total_count"]
        page += 1
      end
    end

    def fetch_reports_details_raw(params)
      fetch_reports_raw(api_url(:details), params)
    end

    def fetch_reports_summary_raw(params)
      fetch_reports_raw(api_url(:summary), params)
    end

    private

    # @param url [String]
    # @param params [Hash]: Toggl API params
    def fetch_reports_raw(url, params)
      logger.info "Fetching Toggl reports for params #{params}" if logger
      params = { user_agent: @user_agent }.merge(params)
      response = HTTParty.get(
        url,
        headers: headers,
        query: params,
        basic_auth: credentials
      )

      handle_response(response)
    end

    def headers
      { "Content-Type" => "application/json" }
    end

    def credentials
      {
        username: @api_token,
        password: "api_token"
      }
    end

    def handle_response(response)
      if response.code == 200 || response.code == 201
        JSON.parse(response.body)
      else
        fail(Error, "Toggl API error #{response.code}: #{response.body}")
      end
    end

    def api_url(resource)
      "#{API_URL}/#{resource}"
    end
  end
end
