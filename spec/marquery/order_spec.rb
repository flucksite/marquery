# frozen_string_literal: true

RSpec.describe Marquery::Order do
  describe ".validate!" do
    it "returns :asc unchanged" do
      expect(described_class.validate!(:asc)).to eq(:asc)
    end

    it "returns :desc unchanged" do
      expect(described_class.validate!(:desc)).to eq(:desc)
    end

    it "raises for unknown values" do
      expect { described_class.validate!(:sideways) }
        .to raise_error(ArgumentError, /Invalid order/)
    end

    it "raises for string variants" do
      expect { described_class.validate!("asc") }
        .to raise_error(ArgumentError, /Invalid order/)
    end
  end
end
