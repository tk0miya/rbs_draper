# frozen_string_literal: true

require "rails"

module RbsDraper
  class InstallGenerator < Rails::Generators::Base
    def create_raketask
      create_file "lib/tasks/rbs_draper.rake", <<~RUBY
        begin
          require 'rbs_draper/rake_task'
          RbsDraper::RakeTask.new
        rescue LoadError
          # failed to load rbs_draper. Skip to load rbs_draper tasks.
        end
      RUBY
    end
  end
end
