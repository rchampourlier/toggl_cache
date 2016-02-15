# Load dependencies
require 'rubygems'
require 'bundler/setup'

ENV['TOGGL_CACHE_ENV'] = 'test'

if ENV['CI']
  # Running on CI, setup Coveralls
  require 'coveralls'
  Coveralls.wear!
else
  # Running locally, setup simplecov
  require 'simplecov'
  require 'simplecov-json'
  SimpleCov.start do
    add_filter do |src|
      # Ignoring files from the spec directory
      src.filename =~ %r{/spec/}
    end
  end
  SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
end

$LOAD_PATH.unshift File.expand_path('../..', __FILE__) # root
$LOAD_PATH.unshift File.expand_path('../../spec', __FILE__)
require 'config/boot'

require 'lib/toggl_cache'

# Cleaning database after each test
require 'lib/toggl_cache/issue'
require 'lib/toggl_cache/project_state'
RSpec.configure do |config|
  config.after(:each) do
    TogglCache::Issue.destroy_all
    TogglCache::ProjectState.destroy_all
  end
end