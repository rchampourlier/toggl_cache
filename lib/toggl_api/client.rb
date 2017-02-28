# frozen_string_literal: true
require "uri"
require "httparty"
require "toggl_api/base_client"

module TogglAPI

  # The Toggl API Client
  class Client < BaseClient
    API_URL = "https://toggl.com/api/v8"

    def update_time_entry(id, data)
      perform_request(
        verb: :put,
        url: "#{API_URL}/time_entries/#{id}",
        headers: default_headers,
        query: data
      )
    end

    private

    def perform_request(verb: :get, url:, headers: {}, query:, credentials: {})
      response = HTTParty.send(
        verb,
        url,
        headers: headers,
        query: { user_agent: user_agent }.merge(query),
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
  end
end
