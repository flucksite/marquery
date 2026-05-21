# frozen_string_literal: true

RSpec.describe Marquery::Helpers do
  let(:fake_renderer) do
    Class.new do
      include Marquery::MarkdownToHtml

      def markdown_to_html(content)
        "<rendered>#{content}</rendered>"
      end
    end
  end

  describe ".markdown" do
    it "renders a String through the default renderer" do
      result = described_class.markdown("# Hello")
      expect(result).to match(%r{<h1.*>.*Hello.*</h1>}m)
    end

    it "accepts a custom renderer" do
      result = described_class.markdown("body", renderer: fake_renderer)
      expect(result).to eq("<rendered>body</rendered>")
    end

    it "calls #to_html on a Marquery::Renderable" do
      entry = Marquery::Entry.new(
        slug: "post",
        title: "Post",
        content: "Hello **world**"
      )
      expect(described_class.markdown(entry)).to include("<strong>world</strong>")
    end

    it "returns an empty string for nil" do
      expect(described_class.markdown(nil)).to eq("")
    end

    it "raises for unsupported types" do
      expect { described_class.markdown(42) }.to raise_error(ArgumentError, /markdown expects/)
    end
  end

  describe "when included" do
    let(:host) do
      Class.new { include Marquery::Helpers }
    end

    it "exposes markdown as an instance method" do
      expect(host.new.markdown("# Hello")).to match(%r{<h1.*>.*Hello.*</h1>}m)
    end
  end
end
