# frozen_string_literal: true

require "rbs"
require "rbs_draper/decorator"

class Account
  include Draper::Decoratable

  def meth; end
end

class Article
  include Draper::Decoratable

  def meth; end
end

class AccountDecorator < Draper::Decorator
end

class ArticleDecorator < Draper::Decorator
  delegate_all
end

RSpec.describe RbsDraper::Decorator do
  describe ".class_to_rbs" do
    subject { described_class.class_to_rbs(klass, rbs_builder) }

    let(:rbs_builder) do
      loader = RBS::EnvironmentLoader.new
      loader.add path: Pathname("spec/sig")
      RBS::DefinitionBuilder.new env: RBS::Environment.from_loader(loader).resolve_type_names
    end

    context 'When a decorater without "delegate_all" given' do
      let(:klass) { AccountDecorator }
      let(:expected) do
        <<~RBS
          class AccountDecorator < Draper::Decorator
            def object: () -> Account
          end
        RBS
      end

      it "Generate type definition without additional methods" do
        expect(subject).to eq expected
      end
    end

    context 'When a decorater with "delegate_all" given' do
      let(:klass) { ArticleDecorator }
      let(:expected) do
        <<~RBS
          class ArticleDecorator < Draper::Decorator
            def object: () -> Article

            def meth: () -> void
          end
        RBS
      end

      it "Generate type definition with additional methods" do
        expect(subject).to eq expected
      end
    end
  end
end
