# TogglCache

Fetches reports data from Toggl API and caches them in a PostgreSQL database.

This allows you to build applications performing complex operations on a large number of Toggl content without the Toggl API latency. You may also use it to backup your precious data!

[![Build Status](https://travis-ci.org/rchampourlier/toggl_cache.svg)](https://travis-ci.org/rchampourlier/toggl_cache)
[![Code Climate](https://codeclimate.com/repos/58d7ff3b88ccb7027b000baa/badges/182b308109bf20bd9dbf/gpa.svg)](https://codeclimate.com/repos/58d7ff3b88ccb7027b000baa/feed)
[![Test Coverage](https://codeclimate.com/repos/58d7ff3b88ccb7027b000baa/badges/182b308109bf20bd9dbf/coverage.svg)](https://codeclimate.com/repos/58d7ff3b88ccb7027b000baa/coverage)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'toggl_cache'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install toggl_cache

## Usage

Inside of `bin/console`:

```ruby
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
client = TogglCache::Client.new(
  api_token: 'SOME-API-TOKEN',
  user_agent: 'MyCustomTogglCache',
  logger: logger
)
TogglCache.sync_reports(client, 'TOGGL-WORKSPACE-ID')
```

## The CLI

```
ruby lib/toggl_cli.rb [batch|help]
```

## Contributing

1. Fork it ( https://github.com/rchampourlier/toggl_cache/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Check the [code of conduct](CODE_OF_CONDUCT.md).
