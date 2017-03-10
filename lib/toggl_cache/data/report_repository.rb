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
        pid
        project
        uid
        user
        task
        tid
      ).freeze

      # It inserts a new issue row with the specified data.
      # If the issue already exists (unicity key is `id`)
      # the row is updated instead.
      def self.create_or_update(report)
        id = report["id"].to_s
        if exist_with_id?(id)
          update_where({ id: id }, row(report: report))
        else
          table.insert row(report: report, insert_created_at: true)
        end
      end

      def self.find_by_id(id)
        table.where(id: id).first
      end

      def self.exist_with_id?(id)
        table.where(id: id).count != 0
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
          report: new_report,
          insert_created_at: insert_created_at,
          insert_updated_at: insert_updated_at
        )
        new_report
      end

      def self.map_report_attributes(report:)
        new_report = report.select { |k, _| MAPPED_REPORT_ATTRIBUTES.include?(k) }
        new_report = new_report.merge(
          duration: report["dur"] / 1_000,
          end: report["end"] ? Time.parse(report["end"]) : nil,
          id: report["id"].to_s,
          start: Time.parse(report["start"]),
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
