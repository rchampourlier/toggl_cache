# frozen_string_literal: true
require "logger"
require "toggl_api/reports_client"
require "toggl_cache/data/report_repository"
require "toggl_cache/version"

# Facility to store/cache Toggl reports data in a PostgreSQL database.
module TogglCache
  HOUR = 3_600
  DAY = 24 * HOUR
  WEEK = 7 * DAY
  DEFAULT_DATE_SINCE = Time.now - 1 * WEEK
  DEFAULT_WORKSPACE_ID = ENV["TOGGL_WORKSPACE_ID"]

  # Fetches new and updated reports from the specified start
  # date to now. By default, fetches all reports since 1 month
  # ago, allowing updates on old reports to update the cached
  # reports too.
  #
  # The fetched reports either update the already
  # existing ones, or create new ones.
  #
  # @param client [TogglAPI::Client] a configured client
  # @param workspace_id [String] Toggl workspace ID (mandatory)
  # @param date_since [Date] Date since when to fetch
  #   the reports.
  def self.sync_reports(client: default_client,
                        date_since: default_date_since)
    reports = fetch_reports(
      client: client,
      date_since: date_since
    )
    process_reports(reports)
  end

  # Fetch from Toggl
  #
  # Handles a fetch over multiple years, which requires splitting the requests
  # over periods extending on a single year (Toggl API requirement).
  # # @param client [TogglCache::Client] configured client
  # @param workspace_id [String] Toggl workspace ID
  # @param date_since [Date] Date since when to fetch
  #   the reports
  # @param date_until [Date] Date until when to fetch
  #   the reports, defaults to Time.now
  def self.fetch_reports(
    client: default_client,
    workspace_id: default_workspace_id,
    date_since:,
    date_until: Time.now
  )
    if date_since && date_until.year > date_since.year
      fetch_reports(
        client: client,
        workspace_id: workspace_id,
        date_since: date_since,
        date_until: Date.new(date_since.year, 12, 31)
      ) + fetch_reports(
        client: client,
        workspace_id: workspace_id,
        date_since: Date.new(date_since.year + 1, 1, 1),
        date_until: date_until
      )
    else
      options = {
        workspace_id: workspace_id, until: date_until.strftime("%Y-%m-%d")
      }
      options[:since] = date_since.strftime("%Y-%m-%d") unless date_since.nil?
      client.fetch_reports(options)
    end
  end

  def self.process_reports(reports)
    reports.each do |report|
      Data::ReportRepository.create_or_update(report)
    end
  end

  def self.default_client(logger: default_logger)
    return TogglAPI::ReportsClient.new(logger: logger) if logger
    TogglAPI::ReportsClient.new
  end

  def self.default_workspace_id
    DEFAULT_WORKSPACE_ID
  end

  def self.default_date_since
    DEFAULT_DATE_SINCE
  end

  def self.default_logger
    logger = ::Logger.new(STDOUT)
    logger.level = default_log_level
    logger
  end

  def self.default_log_level
    Logger.const_get(ENV["TOGGL_CACHE_LOG_LEVEL"]&.upcase || "ERROR")
  end
end
