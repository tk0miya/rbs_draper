# frozen_string_literal: true

require "rbs_draper/decoratable"

class Account
  include Draper::Decoratable
end

class AccountDecorator < Draper::Decorator
end

RSpec.describe RbsDraper::Decoratable do
  describe ".all" do
    subject { described_class.all }

    it "returns a list of decoratables" do
      is_expected.to eq [Account]
    end
  end

  describe ".class_to_rbs" do
    subject { described_class.class_to_rbs(klass) }

    let(:klass) { Account }
    let(:expected) do
      <<~RBS
        class Account < Object
          def decorate: () -> AccountDecorator
        end
      RBS
    end

    it "Generate type definition correctly" do
      expect(subject).to eq expected
    end
  end
end
