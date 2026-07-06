# frozen_string_literal: true

require "draper"

module RbsDraper
  module Decoratable
    def self.all #: Array[singleton(Draper::Decoratable)]
      ObjectSpace.each_object.select do |obj|
        obj.is_a?(Class) && obj < ::Draper::Decoratable && obj.decorator_class
      rescue StandardError
        nil
      end
    end

    # @rbs klass: singleton(Draper::Decoratable)
    def self.class_to_rbs(klass) #: String
      Generator.new(klass).generate
    end

    class Generator
      attr_reader :klass #: singleton(Draper::Decoratable)
      attr_reader :klass_name #: String

      # @rbs klass: singleton(Draper::Decoratable)
      def initialize(klass) #: void
        @klass = klass
        @klass_name = klass.name || ""
      end

      def generate #: String
        format <<~RBS
          #{header}
          #{method_decls}
          #{footer}
        RBS
      end

      private

      # @rbs rbs: String
      def format(rbs) #: String
        parsed = RBS::Parser.parse_signature(rbs)
        StringIO.new.tap do |out|
          RBS::Writer.new(out:).write(parsed[1] + parsed[2])
        end.string
      end

      def header #: String
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

      def method_decls #: String
        "def decorate: () -> #{klass.decorator_class.name}"
      end

      def footer #: String
        "end\n" * klass.module_parents.size
      end

      def module_names #: Array[String]
        klass.module_parents.reverse[1..].map do |mod|
          mod.name.split("::").last
        end
      end
    end
  end
end
