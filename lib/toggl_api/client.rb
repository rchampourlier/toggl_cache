# frozen_string_literal: true
require "uri"
require "httparty"
require "toggl_api/base_client"

module TogglAPI

  # The Toggl API Client
  class Client < BaseClient
    API_URL = "https://www.toggl.com/api/v8"

    # Update the Toggl time entry with the specified `ìd` using
    # the provided `time_entry` data.
    def update_time_entry(id:, time_entry:)
      perform_request(
        verb: :put,
        url: "#{API_URL}/time_entries/#{id}",
        body: { time_entry: time_entry }
      )["data"]
    end

    # Get the projects from the specified workspace.
    def get_workspace_projects(workspace_id: default_workspace_id, active: "true")
      perform_request(
        url: "#{API_URL}/workspaces/#{workspace_id}/projects",
        query: { active: active }
      )
    end

    def get_project_tasks(project_id:)
      perform_request(
        url: "#{API_URL}/projects/#{project_id}/tasks"
      ) || []
    end

    private

    def perform_request(verb: :get, url:, headers: default_headers, query: {}, body: {})
      response = HTTParty.send(
        verb,
        url,
        headers: headers,
        query: { user_agent: default_user_agent }.merge(query),
        body: body.to_json,
        basic_auth: credentials
      )

      begin
        if response.code == 200 || response.code == 201
          return nil if response.body == 'null'
          JSON.parse(response.body)
        else
          logger.error "Error (response code #{response.code}, content '#{response.body.strip}')"
          nil
        end
      # rescue => e
        # TODO: fix this too large rescue
        # logger.error "Exception (#{e})"
      end
    end
  end
end
