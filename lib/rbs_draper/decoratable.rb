# frozen_string_literal: true

require "draper"

module RbsDraper
  module Decoratable
    #: () -> Array[singleton(Draper::Decoratable)]
    def self.all
      ObjectSpace.each_object.select do |obj|
        obj.is_a?(Class) && obj < ::Draper::Decoratable && obj.decorator_class
      rescue StandardError
        nil
      end
    end

    #: (singleton(Draper::Decoratable) klass) -> String
    def self.class_to_rbs(klass)
      Generator.new(klass).generate
    end

    class Generator
      attr_reader :klass #: singleton(Draper::Decoratable)
      attr_reader :klass_name #: String

      #: (singleton(Draper::Decoratable) klass) -> void
      def initialize(klass)
        @klass = klass
        @klass_name = klass.name || ""
      end

      #: () -> String
      def generate
        format <<~RBS
          #{header}
          #{method_decls}
          #{footer}
        RBS
      end

      private

      #: (String rbs) -> String
      def format(rbs)
        parsed = RBS::Parser.parse_signature(rbs)
        StringIO.new.tap do |out|
          RBS::Writer.new(out: out).write(parsed[1] + parsed[2])
        end.string
      end

      #: () -> String
      def header
        namespace = +""
        klass_name.split("::").map do |mod_name|
          namespace += "::#{mod_name}"
          mod_object = Object.const_get(namespace)
          case mod_object
          when Class
            # @type var superclass: Class
            superclass = _ = mod_object.superclass
            superclass_name = superclass.name || "Object"

            "class #{mod_name} < ::#{superclass_name}"
          when Module
            "module #{mod_name}"
          else
            raise "unreachable"
          end
        end.join("\n")
      end

      #: () -> String
      def method_decls
        "def decorate: () -> #{klass.decorator_class.name}"
      end

      #: () -> String
      def footer
        "end\n" * klass.module_parents.size
      end

      #: () -> Array[String]
      def module_names
        klass.module_parents.reverse[1..].map do |mod|
          mod.name.split("::").last
        end
      end
    end
  end
end
