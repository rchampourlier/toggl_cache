# frozen_string_literal: true
require "toggl_cache/data"
require "active_support/inflector"

module TogglCache
  module Data

    # Repository for Toggl reports.
    #
    # TODO: should be used through instances
    # TODO: #table should be private
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
      def create_or_update(report)
        id = report["id"].to_s
        if exist_with_id?(id)
          update_where({ id: id }, row(report: report))
        else
          table.insert row(report: report, insert_created_at: true)
        end
      end

      def find_by_id(id)
        table.where(id: id).first
      end

      def exist_with_id?(id)
        table.where(id: id).count != 0
      end

      def delete_where(where_data)
        table.where(where_data).delete
      end

      def update_where(where_data, values)
        table.where(where_data).update(values)
      end

      def first(by: :start)
        table.order(by).first
      end

      def first_where(where_data)
        table.where(where_data).first
      end

      def index
        table.entries
      end

      def count
        table.count
      end

      # Returns reports whose `start` time is within the specified range.
      #
      # @param since: [Time]
      # @param until: [Time]
      def starting(time_since:, time_until:)
        table.where("start >= ? AND start <= ?", time_since, time_until).entries
      end

      def delete_starting(time_since:, time_until:)
        table.where("start >= ? AND start <= ?", time_since, time_until).delete
      end

      # @param pid [Integer]
      # @param tid [Integer] optional
      def where(project_id:, task_id: nil)
        where_criteria = { pid: project_id }
        where_criteria[:tid] = tid if task_id
        table.where(where_criteria).entries
      end

      private

      def table
        DB[:toggl_cache_reports]
      end

      def row(report:, insert_created_at: false, insert_updated_at: true)
        new_report = map_report_attributes(report: report)
        new_report = add_timestamps(
          report: new_report,
          insert_created_at: insert_created_at,
          insert_updated_at: insert_updated_at
        )
        new_report
      end

      def map_report_attributes(report:)
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

      def add_timestamps(report:, insert_created_at:, insert_updated_at:)
        new_report = {}.merge(report)
        new_report["created_at"] = Time.now if insert_created_at
        new_report["updated_at"] = Time.now if insert_updated_at
        new_report
      end
    end
  end
end
