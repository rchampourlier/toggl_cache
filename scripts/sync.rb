#!/usr/bin/env ruby

# Usage:
#
#   - Syncs reports since 1 month:
#       ruby scripts/sync.rb
#
#   - Sync reports since the specified date (use Ruby-parseable
#     format):
#       ruby scripts/sync.rb 2015-01-01

# Load dependencies
require 'rubygems'
require 'bundler/setup'

$LOAD_PATH.unshift File.expand_path('../..', __FILE__)
require 'config/boot'

date_since = Time.parse(ARGV[0]) unless ARGV[0].nil? || ARGV[0].empty?
TogglCache.sync_reports(date_since: date_since)
