# frozen_string_literal: true

RSpec.describe Marquery::Attributable do
  let(:host) do
    Class.new do
      include Marquery::Attributable
    end
  end

  describe ".attribute" do
    it "stores configuration in attributes" do
      host.attribute(:foo, type: :string, default: "bar")
      expect(host.attributes).to eq(foo: {type: :string, default: "bar"})
    end

    it "freezes hash defaults" do
      host.attribute(:cfg, default: {key: "value"})
      expect(host.attributes[:cfg][:default]).to be_frozen
    end

    it "freezes nested array defaults" do
      host.attribute(:nested, default: [[1, 2], [3, 4]])
      expect(host.attributes[:nested][:default]).to be_frozen
      expect(host.attributes[:nested][:default].first).to be_frozen
    end

    it "rejects unknown types" do
      expect { host.attribute(:foo, type: :unknown) }
        .to raise_error(ArgumentError, /Unknown attribute type/)
    end

    it "accepts every supported type" do
      Marquery::Attributable::VALID_TYPES.each do |type|
        expect { host.attribute(:"f_#{type}", type: type) }.not_to raise_error
      end
    end
  end
end
