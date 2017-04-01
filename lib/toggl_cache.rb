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
  # @param date_since [Date] Date since when to fetch
  #   the reports.
  # @param date_until [Date] Date until when to fetch. Defaults to `Time.now`.
  # @param client [TogglAPI::Client] a configured client
  def self.sync_reports(
    date_since: default_date_since,
    date_until: Time.now,
    logger: default_logger,
    client: default_client
  )
    logger.info "Syncing reports from #{date_since} to #{date_until}."
    clear_cache(
      time_since: Time.parse("#{date_since} 00:00:00Z"),
      time_until: Time.parse("#{date_until} 23:59:59Z"),
      logger: logger
    )
    fetch_reports(
      client: client,
      date_since: date_since,
      date_until: date_until
    ) do |reports|
      process_reports(reports)
    end
  end

  # Performs a full synchronization check, from the time of the first
  # report in the cache to now. Proceeds by comparing reports total
  # duration from Toggl (using the Reports API) and the total contained
  # in the cache. If a difference is detected, proceeds monthly and
  # clear and reconstructs the cache for the concerned month.
  #
  # TODO: enable detecting a change in project/task level aggregates.
  def self.sync_check_and_fix(logger: default_logger)
    reports = TogglCache::Data::ReportRepository.new
    first_report = reports.first

    year_start = first_report[:start].year
    year_end = Time.now.year
    month_start = first_report[:start].month
    month_end = Time.now.month

    (year_start..year_end).each do |year|
      year_toggl = TogglCache.toggl_total(year: year)
      year_cache = TogglCache.cache_total(year: year)
      if year_toggl == year_cache
        logger.info "Checked total for #{year}: ✅ (#{year_toggl})"
        next
      end
      logger.info "Checked total for #{year}: ❌ (Toggl: #{year_toggl}, cache: #{year_cache})"
      (1..12).each do |month|
        next if year == year_start && month < month_start
        next if year == year_end && month > month_end
        month_toggl = TogglCache.toggl_total(year: year, month: month)
        month_cache = TogglCache.cache_total(year: year, month: month)
        if month_toggl == month_cache
          logger.info "Checked total for #{year}/#{month}: ✅ (#{month_toggl})"
        else
          logger.info "Checked total for #{year}/#{month}: ❌ (Toggl: #{month_toggl}, cache: #{month_cache})"
          TogglCache.clear_cache_for_month(year: year, month: month, logger: logger)
          TogglCache.sync_reports_for_month(year: year, month: month, logger: logger)
        end
      end
    end
  end

  # An easy-to-use method to sync reports for a given month. Simply
  # performs a call to `sync_reports`.
  #
  # @param year: [Integer]
  # @param month: [Integer
  # @param logger: [Logger] (optional)
  def self.sync_reports_for_month(year:, month:, logger: default_logger)
    date_since = Date.civil(year, month, 1)
    date_until = Date.civil(year, month, -1)
    sync_reports(
      date_since: date_since,
      date_until: date_until,
      logger: logger
    )
  end

  # Remove TogglCache's reports between the specified dates.
  def self.clear_cache(time_since:, time_until:, logger: default_logger)
    logger.info "Clearing cache from #{time_since} to #{time_until}."
    reports = Data::ReportRepository.new
    reports.delete_starting(
      time_since: time_since,
      time_until: time_until
    )
  end

  # Remove TogglCache's reports for the specified month.
  def self.clear_cache_for_month(year:, month:, logger: default_logger)
    date_since = Date.civil(year, month, 1)
    date_until = Date.civil(year, month, -1)
    clear_cache(
      time_since: Time.parse("#{date_since} 00:00:00Z"),
      time_until: Time.parse("#{date_until} 23:59:59Z"),
      logger: logger
    )
  end

  # Returns the total duration from Toggl (using Reports API)
  # for the specified year or month.
  def self.toggl_total(year:, month: nil)
    reports_client = TogglAPI::ReportsClient.new
    date_since = month ? Date.civil(year, month, 1) : Date.civil(year, 1, 1)
    date_until = month ? Date.civil(year, month, -1) : Date.civil(year, 12, -1)
    total_grand = reports_client.fetch_reports_summary_raw(
      since: date_since.to_s,
      until: date_until.to_s,
      workspace_id: ENV["TOGGL_WORKSPACE_ID"]
    )["total_grand"]
    total_grand ? total_grand / 3600 / 1000 : 0
  end

  # Returns the total duration in TogglCache reports
  # for the specified year or month.
  def self.cache_total(year:, month: nil)
    reports = TogglCache::Data::ReportRepository.new
    date_since = month ? Date.civil(year, month, 1).to_s : Date.civil(year, 1, 1)
    date_until = month ? Date.civil(year, month, -1).to_s : Date.civil(year, 12, -1)
    time_since = Time.parse("#{date_since} 00:00:00Z")
    time_until = Time.parse("#{date_until} 23:59:59Z")
    reports.starting(
      time_since: time_since,
      time_until: time_until
    ).inject(0) { |sum, r| sum + r[:duration] } / 3600
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
    date_until: Time.now,
    &block
  )
    raise "You must give a block to process fetched records" unless block_given?
    if date_since && date_until.year > date_since.year
      [
        [date_since, Date.new(date_since.year, 12, 31)],
        [Date.new(date_since.year + 1, 1, 1), date_until]
      ].each do |dates|
        fetch_reports(
          client: client,
          workspace_id: workspace_id,
          date_since: dates.first,
          date_until: dates.last,
          &block
        )
      end
    else
      options = {
        workspace_id: workspace_id, until: date_until.strftime("%Y-%m-%d")
      }
      options[:since] = date_since.strftime("%Y-%m-%d") unless date_since.nil?
      client.fetch_reports(options, &block)
    end
  end

  def self.process_reports(reports, logger: default_logger)
    logger.debug "Processing #{reports.count} Toggl reports"
    repository = Data::ReportRepository.new
    reports.each do |report|
      repository.create_or_update(report)
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
