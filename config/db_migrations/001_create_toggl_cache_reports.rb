#!/usr/bin/env ruby
# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :toggl_cache_reports do
      String :description
      Integer :duration
      DateTime :end
      Integer :pid
      String :project
      String :uid
      String :user
      DateTime :start
      String :task
      Integer :tid
      String :id, unique: true
      DateTime :toggl_updated

      # Timestamps
      DateTime :created_at
      DateTime :updated_at
    end
  end

  down do
    drop_table(:toggl_cache_reports)
  end
end
