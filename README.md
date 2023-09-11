# rbs_draper

rbs_draper is a generator for decorators using [Draper](https://github.com/drapergem/draper).

## Installation

Add a new entry to your Gemfile and run `bundle install`:

    group :development do
      gem 'rbs_draper', require: false
    end

After the installation, please run rake task generator:

    bundle exec rails g rbs_draper:install

If you have decorators having different names from models, you can specify the mapping from
decorator names to model names in `lib/tasks/rbs_draper.rake`. For example:

    RbsDraper::RakeTask.new do |task|
      task.mapping = -> { { AdminUserDecorator => User } }
    end

## Accessing Helpers

If your decorators access to the custom helpers via `#h` method, you need to define the types
for the custom helpers into `Draper::HelperProxy`:

```ruby 
module Draper
  class HelperProxy
    include MyCustomHelper

    def my_custom_helper_method: (String, String) -> String
  end
end
```

## Usage

1. Run `rbs:draper:clean` at first
2. Run other RBS generators (ex. `rbs prototype`, `rbs_rails` and so on)
3. Run `rbs:draper:setup` task finally.

       bundle exec rake rbs:draper:setup

Then rbs_draper will scan your source code and type signatures, and will generate
RBS files into `sig/draper` directory.

Note: rbs_draper uses other type signatures to generate decorators' signature.
      So it should be run after other tasks.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also
run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then put
a git tag (ex. `git tag v1.0.0`) and push it to the GitHub.  Then GitHub Actions
will release a new package to [rubygems.org](https://rubygems.org) automatically.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tk0miya/rbs_draper.
This project is intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [code of conduct](https://github.com/tk0miya/rbs_draper/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RbsDraper project's codebases, issue trackers is expected to
follow the [code of conduct](https://github.com/tk0miya/rbs_draper/blob/main/CODE_OF_CONDUCT.md).
