# frozen_string_literal: true

source "https://rubygems.org", cooldown: 7

# Specify your gem's dependencies in rbs_draper.gemspec
gemspec

gem "rake", "~> 13.4"

gem "rubocop", "~> 1.88"
gem "rubocop-numbered-params"
gem "rubocop-rake"
gem "rubocop-rbs_inline"
gem "rubocop-rspec"

group :development do
  gem "rbs-inline", require: false
  gem "rspec", require: false
  gem "rspec-daemon", require: false

  gem "steep"
end

# dependencies only for signature
group :signature do
  gem "activerecord"
  gem "railties"
end
