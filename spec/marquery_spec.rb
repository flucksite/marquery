# frozen_string_literal: true

RSpec.describe Marquery do
  it "has a version number" do
    expect(Marquery::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end

  describe ".config" do
    it "returns a default configuration" do
      expect(Marquery.config.data_dir).to eq("spec/fixtures/marquery")
      expect(Marquery.config.preprocessor).to be_nil
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      Marquery.configure do |c|
        c.data_dir = "elsewhere"
      end
      expect(Marquery.config.data_dir).to eq("elsewhere")
    end
  end

  describe ".eager_load!" do
    it "calls load! on every registered query class" do
      klass = Class.new do
        include Marquery::Query
        dir "blog_post"
      end

      expect(klass.loaded?).to be(false)
      Marquery.eager_load!
      expect(klass.loaded?).to be(true)
    end
  end
end
