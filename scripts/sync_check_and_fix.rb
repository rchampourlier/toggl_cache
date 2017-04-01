#!/usr/bin/env ruby
# frozen_string_literal: true

# Check that reports stored in TogglCache match report summaries
# provided by toggl Reports API.
#
# Usage:
#
#     ruby scripts/sync_check_and_fix.rb

# Load dependencies
require "rubygems"
require "bundler/setup"
require "logger"

$LOAD_PATH.unshift File.expand_path("../..", __FILE__)
require "config/boot"

TogglCache.sync_check_and_fix
