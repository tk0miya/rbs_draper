# frozen_string_literal: true

require "rails"

module RbsDraper
  class InstallGenerator < Rails::Generators::Base
    def create_raketask
      create_file "lib/tasks/rbs_draper.rake", <<~RUBY
        begin
          require 'rbs_draper/rake_task'

          RbsDraper::RakeTask.new do |task|
            # If you have decorators having different names from models, you can specify the mapping from decorator names to model names.
            # The value should be a lambda that returns a hash to load decorators and models easily.
            #
            # task.mapping = -> { { AdminUserDecorator => User } }
          end
        rescue LoadError
          # failed to load rbs_draper. Skip to load rbs_draper tasks.
        end
      RUBY
    end
  end
end
