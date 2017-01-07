# frozen_string_literal: true
require "toggl_cache/data"
require "active_support/inflector"

module TogglCache
  module Data

    # Superclass for repositories. Simply provide some shared
    # methods.
    class ReportRepository

      MAPPED_REPORT_ATTRIBUTES = %w(
        description
        project
        uid
        user
        task
      ).freeze

      # It inserts a new issue row with the specified data.
      # If the issue already exists (unicity key is `toggl_id`)
      # the row is updated instead.
      def self.create_or_update(report)
        toggl_id = report["id"]
        if exist_with_toggl_id?(toggl_id)
          update_where({ toggl_id: toggl_id }, row(report))
        else
          table.insert row(report)
        end
      end

      def self.find_by_toggl_id(toggl_id)
        table.where(toggl_id: toggl_id).first
      end

      def self.exist_with_toggl_id?(toggl_id)
        table.where(toggl_id: toggl_id).count != 0
      end

      def self.delete_where(where_data)
        table.where(where_data).delete
      end

      def self.update_where(where_data, values)
        table.where(where_data).update(values)
      end

      def self.first_where(where_data)
        table.where(where_data).first
      end

      def self.index
        table.entries
      end

      def self.count
        table.count
      end

      def self.table
        DB[:toggl_cache_reports]
      end

      def self.row(report:, insert_created_at: false, insert_updated_at: true)
        new_report = map_report_attributes(report: report)
        new_report = add_timestamps(
          report: report,
          insert_created_at: insert_created_at,
          insert_updated_at: insert_updated_at
        )
        new_report
      end

      def self.map_report_attributes(report:)
        new_report = report.slice(*MAPPED_REPORT_ATTRIBUTES)
        new_report = report.merge(
          duration: report["dur"] / 1_000,
          end: report["end"] ? Time.parse(report["end"]) : nil,
          start: Time.parse(report["start"]),
          toggl_id: report["id"],
          toggl_updated: Time.parse(report["updated"])
        )
        new_report
      end

      def self.add_timestamps(report:, insert_created_at:, insert_updated_at:)
        new_report = {}.merge(report)
        new_report["created_at"] = Time.now if insert_created_at
        new_report["updated_at"] = Time.now if insert_updated_at
        new_report
      end
    end
  end
end