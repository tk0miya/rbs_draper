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
      attr_reader :klass, :klass_name

      def initialize(klass)
        @klass = klass
        @klass_name = RbsRails::Util.module_name(klass)
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
        namespace = +""
        klass_name.split("::").map do |mod_name|
          namespace += "::#{mod_name}"
          mod_object = Object.const_get(namespace)
          case mod_object
          when Class
            # @type var superclass: Class
            superclass = _ = mod_object.superclass
            superclass_name = RbsRails::Util.module_name(superclass)

            "class #{mod_name} < ::#{superclass_name}"
          when Module
            "module #{mod_name}"
          else
            raise "unreachable"
          end
        end.join("\n")
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
