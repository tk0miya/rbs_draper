# frozen_string_literal: true

require "fileutils"
require "rbs/cli"
require "pathname"
require "rake"
require "rake/tasklib"

module RbsDraper
  class RakeTask < Rake::TaskLib
    attr_accessor :name, :signature_root_dir

    def initialize(name = :'rbs:draper', &block)
      super()

      @name = name
      @signature_root_dir = Pathname(Rails.root / "sig/draper")

      block&.call(self)

      define_clean_task
      define_base_class_generate_task
      define_decoratables_generate_task
      define_decorators_generate_task
      define_setup_task
    end

    def define_setup_task
      desc "Run all tasks of rbs_draper"

      deps = [:"#{name}:clean", :"#{name}:base_class:generate", :"#{name}:decoratables:generate",
              :"#{name}:decorators:generate"]
      task("#{name}:setup": deps)
    end

    def define_clean_task
      desc "Clean up generated RBS files"
      task("#{name}:clean": :environment) do
        sh "rm", "-rf", signature_root_dir.to_s
      end
    end

    def define_base_class_generate_task
      desc "Generate RBS files for base classes"
      task("#{name}:base_class:generate": :environment) do
        require "rbs_draper"  # load RbsDraper lazily

        signature_root_dir.mkpath

        basedir = Pathname(__FILE__).dirname
        FileUtils.cp basedir / "sig/decoratable.rbs", signature_root_dir
        FileUtils.cp basedir / "sig/decorator.rbs", signature_root_dir
      end
    end

    def define_decoratables_generate_task
      desc "Generate RBS files for decoratable models"
      task("#{name}:decoratables:generate": :environment) do
        require "rbs_draper"  # load RbsDraper lazily

        Rails.application.eager_load!

        RbsDraper::Decoratable.all.each do |klass|
          path = signature_root_dir / "app/models/#{klass.name.to_s.underscore}.rbs"
          path.dirname.mkpath
          rbs = RbsDraper::Decoratable.class_to_rbs(klass)
          path.write rbs if rbs
        end
      end
    end

    def define_decorators_generate_task
      desc "Generate RBS files for decorators"
      task("#{name}:decorators:generate": :environment) do
        Rails.application.eager_load!

        Draper::Decorator.descendants.each do |klass|
          path = signature_root_dir / "app/decorators/#{klass.name.underscore}.rbs"
          path.dirname.mkpath
          rbs = RbsDraper::Decorator.class_to_rbs(klass, rbs_builder)
          path.write rbs if rbs
        end
      end
    end

    private

    def rbs_builder
      return @rbs_builder if @rbs_builder

      loader = RBS::CLI::LibraryOptions.new.loader
      loader.add path: Pathname("sig")
      @rbs_builder = RBS::DefinitionBuilder.new env: RBS::Environment.from_loader(loader).resolve_type_names
    end
  end
end
