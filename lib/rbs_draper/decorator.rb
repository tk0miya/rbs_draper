# frozen_string_literal: true

require "draper"
require "rbs"

module RbsDraper
  module Decorator
    # @rbs klass: singleton(Draper::Decorator)
    # @rbs rbs_builder: RBS::DefinitionBuilder
    # @rbs decorated_class: singleton(Class)?
    def self.class_to_rbs(klass, rbs_builder, decorated_class: nil) #: String?
      Generator.new(klass, rbs_builder, decorated_class:).generate
    end

    class Generator
      attr_reader :klass #: singleton(Draper::Decorator)
      attr_reader :klass_name #: String
      attr_reader :rbs_builder #: RBS::DefinitionBuilder
      attr_reader :decorated_class #: singleton(Class)?

      # @rbs @decorated_class_def: RBS::Definition
      # @rbs @decorated_class_name: String
      # @rbs @user_defined_class: RBS::Definition

      # @rbs klass: singleton(Draper::Decorator)
      # @rbs rbs_builder: RBS::DefinitionBuilder
      # @rbs decorated_class: singleton(Class)?
      def initialize(klass, rbs_builder, decorated_class: nil) #: void
        @klass = klass
        @klass_name = klass.name || ""
        @rbs_builder = rbs_builder
        @decorated_class = decorated_class
      end

      def generate #: String?
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

      def mixin_decls #: String?
        "extend Draper::Finders[#{decorated_class_name}]" if klass.singleton_class < Draper::Finders
      end

      def class_method_decls #: String?
        "def self.decorate: (#{decorated_class_name} object, **untyped options) -> self"
      end

      def object_method_decls #: String
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

      def method_decls #: String?
        delegated_methods.filter_map do |name, method|
          next if user_defined_class&.methods&.fetch(name, nil)

          "def #{name}: #{method.method_types.join(" | ")}"
        end.join("\n")
      end

      def footer #: String
        "end\n" * klass.module_parents.size
      end

      def module_names #: Array[String]
        klass.module_parents.reverse[1..].map do |mod|
          mod.name.split("::").last
        end
      end

      def decorated_class_def #: RBS::Definition?
        type_name = RBS::TypeName.parse(decorated_class_name).absolute!
        @decorated_class_def ||= rbs_builder.build_instance(type_name)
      rescue StandardError
        nil
      end

      def decorated_class_name #: String
        @decorated_class_name = decorated_class&.name || klass.object_class.name.to_s
      end

      def delegated_methods #: Array[[Symbol, RBS::Definition::Method]]
        return [] unless klass.ancestors.include? ::Draper::AutomaticDelegation

        decorated_klass = decorated_class_def
        return [] unless decorated_klass

        decorated_klass.methods.keys.sort.filter_map do |name|
          method = decorated_klass.methods.fetch(name)
          next if %w[::Object ::BasicObject ::Kernel].include? method.defined_in.to_s

          [name, method] if method.accessibility == :public
        end
      end

      def user_defined_class #: RBS::Definition?
        type_name = RBS::TypeName.parse(klass.name.to_s).absolute!
        @user_defined_class ||= rbs_builder.build_instance(type_name)
      rescue StandardError
        nil
      end
    end
  end
end
