# frozen_string_literal: true

RSpec.describe Marquery::Registry do
  it "registers query classes on inclusion" do
    klass = Class.new do
      include Marquery::Query
      dir "blog_post"
    end

    expect(described_class.classes).to include(klass)
  end

  it "does not register the same class twice" do
    klass = Class.new do
      include Marquery::Query
      dir "blog_post"
    end

    described_class.register(klass)
    described_class.register(klass)
    expect(described_class.classes.count(klass)).to eq(1)
  end

  it "can be reset between tests" do
    Class.new do
      include Marquery::Query
      dir "blog_post"
    end

    described_class.reset!
    expect(described_class.classes).to be_empty
  end
end
