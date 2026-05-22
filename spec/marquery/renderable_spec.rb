# frozen_string_literal: true

RSpec.describe Marquery::Renderable do
  let(:fake_renderer) do
    Class.new do
      include Marquery::MarkdownToHtml

      def markdown_to_html(content)
        "<rendered>#{content}</rendered>"
      end
    end
  end

  let(:model_class) do
    fake = fake_renderer
    Class.new do
      include Marquery::Model
      renderer fake
    end
  end

  let(:entry) do
    model_class.new(
      slug: "post",
      title: "Post",
      content: "Hello ![hero](asset:hero.png) world",
      assets: {"hero.png" => "marquery/blog_post/post/hero.png"}
    )
  end

  describe "#asset" do
    it "returns a leading-slash path for known assets" do
      expect(entry.asset("hero.png")).to eq("/marquery/blog_post/post/hero.png")
    end

    it "raises AssetNotFound for unknown assets" do
      expect { entry.asset("missing.png") }.to raise_error(Marquery::AssetNotFound)
    end
  end

  describe "#asset?" do
    it "returns nil for unknown assets" do
      expect(entry.asset?("missing.png")).to be_nil
    end

    it "returns the path for known assets" do
      expect(entry.asset?("hero.png")).to eq("/marquery/blog_post/post/hero.png")
    end
  end

  describe "#process_content" do
    it "rewrites asset URIs by default" do
      result = entry.process_content("see asset:hero.png here")
      expect(result).to eq("see /marquery/blog_post/post/hero.png here")
    end

    it "delegates to the global preprocessor when configured" do
      Marquery.configure do |c|
        c.preprocessor = ->(raw, item) { "[#{item.slug}] #{raw.upcase}" }
      end

      expect(entry.process_content("body")).to eq("[post] BODY")
    end
  end

  describe "#to_html" do
    it "uses the configured renderer" do
      expect(entry.to_html).to include("<rendered>")
    end
  end

  describe "per-model renderer" do
    it "overrides the default renderer" do
      expect(model_class.renderer).to eq(fake_renderer)
    end

    it "falls back to Marquery::Renderer when none is declared" do
      plain = Class.new { include Marquery::Model }
      expect(plain.renderer).to eq(Marquery::Renderer)
    end

    it "inherits the renderer from a superclass that declared one" do
      parent_class = model_class
      child = Class.new(parent_class)
      expect(child.renderer).to eq(fake_renderer)
    end

    it "allows a subclass to override its parent's renderer" do
      parent_class = model_class
      override_renderer = Class.new do
        include Marquery::MarkdownToHtml

        def markdown_to_html(content)
          "<other>#{content}</other>"
        end
      end

      child = Class.new(parent_class) do
        renderer override_renderer
      end

      expect(child.renderer).to eq(override_renderer)
      expect(parent_class.renderer).to eq(fake_renderer)
    end
  end
end
