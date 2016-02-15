require 'mongoid'

env = ENV['TOGGL_CACHE_ENV']
fail 'TOGGL_CACHE_ENV environment variable must be set' if env.nil?

ENV['MONGOID_ENV'] = env

Mongoid.load! File.expand_path('../mongoid.yml', __FILE__)
