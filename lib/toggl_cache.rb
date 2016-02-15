require 'toggl_cache/report'
require 'toggl_cache/version'

# Facility to store/cache Toggl reports data in a MongoDB datastore
module TogglCache
  DEFAULT_DATE_SINCE = 1.month.ago

  # Fetches new and updated reports from the specified start
  # date to now. By default, fetches all reports since 1 month
  # ago, allowing updates on old reports to update the cached
  # reports too.
  #
  # The fetched reports either update the already
  # existing ones, or create new ones.
  #
  # @param client [TogglCache::Client] configured client
  # @param workspace_id [String] Toggl workspace ID
  # @param date_since [Date] Date since when to fetch
  #   the reports.
  def sync_reports(client, workspace_id, date_since = nil)
    reports = fetch_reports(
      client,
      workspace_id,
      date_since || DEFAULT_DATE_SINCE
    )
    process_reports(reports)
  end
  module_function :sync_reports

  # Fetch from Toggl
  # @param client [TogglCache::Client] configured client
  # @param workspace_id [String] Toggl workspace ID
  # @param date_since [Date] Date since when to fetch
  #   the reports
  # @param date_until [Date] Date until when to fetch
  #   the reports, defaults to Time.now
  def fetch_reports(client, workspace_id, date_since, date_until = Time.now)
    if date_until.year > date_since.year
      fetch_reports(
        client,
        workspace_id,
        date_since,
        date_since.end_of_year
      ) + fetch_reports(
        client,
        workspace_id,
        date_since.end_of_year + 1.day,
        date_until
      )
    else
      options = {
        workspace_id: workspace_id,
        since: date_since.strftime('%Y-%m-%d'),
        until: date_until.strftime('%Y-%m-%d')
      }
      client.fetch_reports_multiple_pages(options)
    end
  end
  module_function :fetch_reports

  def process_reports(reports)
    reports.each do |report|
      Report.create_or_update(report)
    end
  end
  module_function :process_reports
end
