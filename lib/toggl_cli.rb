# frozen_string_literal: true
require "thor"
require "tty-pager"
require "tty-progressbar"
require "tty-spinner"
# require "tty-table"
require File.expand_path("../../config/boot", __FILE__)
require "toggl_api/client"
require "toggl_cache/data/report_repository"

class TogglCLI < Thor
  package_name "TogglCLI"
  include Thor::Shell
  FILTERS = %w(no description user clear).freeze
  SHOW_REPORTS_COLUMNS = %w(description user duration).freeze

  # Batch edition
  # Workflow:
  #   - select source project / task
  #   - provide information about matching reports
  #   - enable user to filter reports
  #   - select target project / task
  #   - apply transformation
  desc "batch", "Batch edition"
  method_option :no_cache_update, desc: "Don't update the local cache", type: :boolean
  def batch
    # TEMP
    # source_project = select_project("Select the source project")
    # source_task = select_task("Select the source task", source_project["id"])
    source_project = { "name" => "technical (fake)", "id" => 9800254 }
    source_task = { "name" => "No task", "id" => nil }
    # END TEMP

    reports = find_reports(source_project["id"], source_task["id"])
    show_reports_info(reports)
    reports = filter_reports(reports)

    unless no?("Move these reports to a new project / task (enter 'n' or 'no' to cancel)")
      target_project = select_project("Select the target project")
      target_task = select_task("Select the target task", target_project["id"])

      say(
        "Will move #{reports.count} reports, " \
        "from #{source_project['name']} > #{source_task['name']} " \
        "to #{target_project['name']} > #{target_task['name']}"
      )
      if yes?("Are you sure? (enter 'y' or 'yes' to continue)")
        say("MOVING!!!")
      end
    end
    # TogglCache::Data::ReportRepository.create_or_update(report)
  end

  private

  def filter_reports(reports)
    begin
      selected_filter = ask("Add filter?", limited_to: FILTERS)
      reports = (
        case selected_filter
        when "no" then reports
        when "description" then propose_description_regexp_filter(reports)
        when "user" then propose_user_filter(reports)
        else raise "Unexpected filter `#{selected_filter}`"
        end
      )
      show_reports_info(reports)
    end while(selected_filter != "no")
    reports
  end

  def propose_description_regexp_filter(reports)
    show_unique_descriptions(reports)
    if yes?("Add regexp filter? (enter 'y' or 'yes' to continue)")
      regexp = eval(ask("Enter regexp (e.g. /string/i - will go through `eval`):"))
      filtered = reports.select { |r| r[:description] =~ regexp }
      show_unique_descriptions(filtered)
      return filtered unless no?("Keep filter? (enter 'n' or 'no' to discard the filter)")
    end
    reports
  end

  def propose_user_filter(reports)
    selected_user = select_in_list(reports.map { |r| r[:user] }.uniq, "Select user")
    filtered = reports.select { |r| r[:user] == selected_user }
    show_reports_info(filtered)
    return filtered unless no?("Keep filter? (enter 'n' or 'no' to discard the filter)")
    reports
  end

  def show_unique_descriptions(reports)
    unique_descriptions = reports.map { |r| r[:description] }.uniq
    say("Found #{unique_descriptions.count} unique descriptions.")
    if yes?("Show unique descriptions? (enter 'y' or 'yes' to show)")
      page(unique_descriptions.join("\n") << "\n")
    end
  end

  def show_reports_info(reports)
    say("#{reports.count} matching reports.")
    show_reports(reports) if yes?("Show reports? (enter 'y' or 'yes' to show)")
  end

  def show_reports(reports)
    report_lines = reports.map do |r|
      report_columns = SHOW_REPORTS_COLUMNS.map do |c|
        r[c.to_sym]
      end
      report_columns.join(" | ")
    end
    page(report_lines.join("\n") << "\n")
  end

  def find_reports(project_id, task_id)
    with_spinner("Fetching matching reports...") do
      where_criteria = { pid: project_id.to_i }
      where_criteria[:tid] = task_id if task_id
      TogglCache::Data::ReportRepository.table.where(where_criteria).entries
    end
  end

  def select_in_list(items, msg)
    items.each.with_index { |item, i| say("  #{i}. #{item}") }
    begin
      index = ask("#{msg} (0-#{items.count - 1})").to_i
    end while(index < 0 || index > items.count - 1)
    items[index]
  end

  def select_project(msg)
    say("Projects:")
    project_name = select_in_list(project_names, msg)
    project = projects.find { |p| p["name"] == project_name }
    say("Selected project `#{project["name"]}`")
    project
  end

  def select_task(msg, project_id)
    source_project_tasks = project_tasks(project_id)
    return { "id" => nil, "name" => "No task" } if source_project_tasks.empty?
    say("Tasks for selected project:")
    source_project_tasks.each.with_index do |task, i|
      say("  #{i}. #{task['name']}")
    end
    begin
      source_task_index = ask("#{msg} (0-#{source_project_tasks.count - 1})").to_i
    end while(source_task_index < 0 || source_task_index > source_project_tasks.count - 1)
    source_task = source_project_tasks[source_task_index]
  end

  def projects
    @projects ||= (
      with_spinner("Fetching projects...") do
        client.get_workspace_projects(active: "both")
      end
    )
  end

  def project_tasks(project_id)
    tasks = with_spinner("Fetching tasks...") do
      client.get_project_tasks(project_id: project_id)
    end
    tasks.map do |task|
      { "id" => task["id"], "name" => task["name"] }
    end
  end

  def project_names
    projects.map { |p| p["name"] }
  end

  def client
    @client ||= TogglAPI::Client.new
  end

  def build_spinner(title)
    TTY::Spinner.new("#{title} [:spinner]")
  end

  def build_bar(msg, count)
    TTY::ProgressBar.new("#{msg} [:bar]", total: count)
  end

  def with_spinner(msg)
    spinner = build_spinner(msg)
    result = nil
    yield
    spinner.run("Done!") { result = yield }
    result
  end

  def page(text)
    pager = TTY::Pager::BasicPager.new
    pager.page(text)
  end
end

TogglCLI.start
