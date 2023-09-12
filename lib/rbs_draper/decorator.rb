# frozen_string_literal: true

require "draper"
require "rbs"

module RbsDraper
  module Decorator
    def self.class_to_rbs(klass, rbs_builder, decorated_class: nil)
      Generator.new(klass, rbs_builder, decorated_class: decorated_class).generate
    end

    class Generator
      attr_reader :klass, :klass_name, :rbs_builder, :decorated_class

      def initialize(klass, rbs_builder, decorated_class: nil)
        @klass = klass
        @klass_name = klass.name || ""
        @rbs_builder = rbs_builder
        @decorated_class = decorated_class
      end

      def generate
        return if decorated_class_def.blank?

        format <<~RBS
          #{header}
          #{mixin_decls}
          #{class_method_decls}
          #{object_method_decls}

          #{method_decls}
          #{footer}
        RBS
      end

      private

      def format(rbs)
        parsed = RBS::Parser.parse_signature(rbs)
        StringIO.new.tap do |out|
          RBS::Writer.new(out: out).write(parsed[1] + parsed[2])
        end.string
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
            superclass_name = superclass.name || "Object"

            "class #{mod_name} < ::#{superclass_name}"
          when Module
            "module #{mod_name}"
          else
            raise "unreachable"
          end
        end.join("\n")
      end

      def mixin_decls
        "extend Draper::Finders[#{decorated_class_name}]" if klass.singleton_class < Draper::Finders
      end

      def class_method_decls
        "def self.decorate: (#{decorated_class_name} object, **untyped options) -> self"
      end

      def object_method_decls
        if decorated_class_name.include?("::")
          <<~RBS
            def initialize: (#{decorated_class_name} object, **untyped options) -> void
            def object: () -> #{decorated_class_name}
          RBS
        else
          <<~RBS
            def initialize: (#{decorated_class_name} object, **untyped options) -> void
            def object: () -> #{decorated_class_name}
            def #{decorated_class_name.underscore}: () -> #{decorated_class_name}
          RBS
        end
      end

      def method_decls
        delegated_methods.filter_map do |name, method|
          next if user_defined_class&.methods&.fetch(name, nil)

          "def #{name}: #{method.method_types.map(&:to_s).join(" | ")}"
        end.join("\n")
      end

      def footer
        "end\n" * klass.module_parents.size
      end

      def module_names
        klass.module_parents.reverse[1..].map do |mod|
          mod.name.split("::").last
        end
      end

      def decorated_class_def
        type_name = RBS::TypeName(decorated_class_name).absolute!
        @decorated_class_def ||= rbs_builder.build_instance(type_name)
      rescue StandardError
        nil
      end

      def decorated_class_name
        @decorated_class_name = decorated_class&.name || klass.object_class.name
      end

      def delegated_methods
        return [] unless klass.ancestors.include? ::Draper::AutomaticDelegation

        decorated_klass = decorated_class_def
        return [] unless decorated_klass

        decorated_klass.methods.keys.sort.filter_map do |name|
          method = decorated_klass.methods[name]
          next if %w[::Object ::BasicObject ::Kernel].include? method.defined_in.to_s

          [name, method] if method.accessibility == :public
        end
      end

      def user_defined_class
        type_name = RBS::TypeName(klass.name.to_s).absolute!
        @user_defined_class ||= rbs_builder.build_instance(type_name)
      rescue StandardError
        nil
      end
    end
  end
end
