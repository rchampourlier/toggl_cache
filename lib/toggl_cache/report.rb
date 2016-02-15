require 'mongoid'

module TogglCache

  # Document to store Toggl report data
  class Report
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'toggl_cache_reports'

    field :description, type: String
    field :duration, type: Integer # seconds
    field :end, type: Time
    field :project, type: String
    field :uid, type: String
    field :user, type: String
    field :start, type: Time
    field :task, type: String
    field :toggl_id, type: String
    field :toggl_updated, type: Time

    def self.find_by_toggl_id(toggl_id)
      where(toggl_id: toggl_id).first
    end

    def self.create_or_update(report)
      doc = find_by_toggl_id(report['id'])
      return update(doc, report) if doc.present?
      create(report)
    end

    def self.create(report)
      update(new, report)
    end

    def self.update(doc, report)
      doc.description = report['description']
      doc.attributes = report.slice(*%w(
        description
        project
        uid
        user
        task
      ))
      doc.duration = report['dur'] / 1000
      doc.end = report['end'] ? Time.parse(report['end']) : nil
      doc.start = Time.parse report['start']
      doc.toggl_id = report['id']
      doc.toggl_updated = Time.parse report['updated']
      doc.save!
      doc
    end
  end
end
