# frozen_string_literal: true

require "draper"
require "rbs_rails"

module RbsDraper
  module Decoratable
    def self.all
      ObjectSpace.each_object.select do |obj|
        obj.is_a?(Class) && obj.ancestors.include?(::Draper::Decoratable) && obj.decorator_class
      rescue StandardError
        nil
      end
    end

    def self.class_to_rbs(klass)
      Generator.new(klass).generate
    end

    class Generator
      attr_reader :klass

      def initialize(klass)
        @klass = klass
      end

      def generate
        RbsRails::Util.format_rbs klass_decl
      end

      private

      def klass_decl
        <<~RBS
          #{header}
          #{method_decls}
          #{footer}
        RBS
      end

      def header
        module_defs = module_names.map { |module_name| "module #{module_name}" }

        superclass_name = RbsRails::Util.module_name(klass.superclass)
        class_name = klass.name.split("::").last
        class_def = if superclass_name.present?
                      "class #{class_name} < #{superclass_name}"
                    else
                      "class #{class_name}"
                    end

        (module_defs + [class_def]).join("\n")
      end

      def method_decls
        "def decorate: () -> #{klass.decorator_class.name}"
      end

      def footer
        "end\n" * klass.module_parents.size
      end

      def module_names
        klass.module_parents.reverse[1..].map do |mod|
          mod.name.split("::").last
        end
      end
    end
  end
end
