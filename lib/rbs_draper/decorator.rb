# frozen_string_literal: true

require "draper"
require "rbs"
require "rbs_rails"

module RbsDraper
  module Decorator
    def self.class_to_rbs(klass, rbs_builder)
      Generator.new(klass, rbs_builder).generate
    end

    class Generator
      attr_reader :klass, :rbs_builder

      def initialize(klass, rbs_builder)
        @klass = klass
        @rbs_builder = rbs_builder
      end

      def generate
        return if decorated_class.blank?

        RbsRails::Util.format_rbs klass_decl
      end

      private

      def klass_decl
        <<~RBS
          #{header}
          def object: () -> #{klass.name.sub(/Decorator$/, "")}

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

      def decorated_class
        type_name = RBS::TypeName(klass.name.sub(/Decorator$/, "")).absolute!
        @decorated_class ||= rbs_builder.build_instance(type_name)
      rescue StandardError
        nil
      end

      def delegated_methods
        return [] unless klass.ancestors.include? ::Draper::AutomaticDelegation

        decorated_class.methods.keys.sort.filter_map do |name|
          method = decorated_class.methods[name]
          next if %w[::Object ::BasicObject ::Kernel].include? method.defined_in.to_s

          [name, method] if method.accessibility == :public
        end
      end

      def user_defined_class
        type_name = RBS::TypeName(klass.name).absolute!
        @user_defined_class ||= rbs_builder.build_instance(type_name)
      rescue StandardError
        nil
      end
    end
  end
end
