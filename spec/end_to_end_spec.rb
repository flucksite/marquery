# frozen_string_literal: true

RSpec.describe "end-to-end rendering" do
  let(:query_class) do
    Class.new do
      include Marquery::Query
      dir "blog_post"
    end
  end

  describe "default pipeline" do
    let(:post) { query_class.new.find("first-post") }

    it "renders the body through Commonmarker" do
      html = post.to_html

      expect(html).to match(%r{<h1.*>.*Hello world.*</h1>}m)
      expect(html).to include("<a href=\"https://example.com\">example</a>")
    end

    it "rewrites asset: URIs to resolved paths" do
      html = post.to_html
      expect(html).to include('src="/spec/fixtures/marquery/blog_post/20260320_first_post/hero.png"')
      expect(html).not_to include("asset:hero.png")
    end

    it "renders the index page content" do
      html = query_class.index_entry.to_html
      expect(html.strip).to eq("<p>Welcome to my blog.</p>")
    end
  end

  describe "custom renderer per model" do
    let(:upcase_renderer) do
      Class.new do
        include Marquery::MarkdownToHtml

        def markdown_to_html(content)
          "<wrap>#{content.upcase}</wrap>"
        end
      end
    end

    let(:custom_model) do
      renderer_class = upcase_renderer
      Class.new do
        include Marquery::Model
        renderer renderer_class
      end
    end

    let(:custom_query) do
      model_class = custom_model
      Class.new do
        include Marquery::Query
        model model_class
        dir "blog_post"
      end
    end

    it "uses the per-model renderer instead of Commonmarker" do
      html = custom_query.new.find("second-post").to_html
      expect(html).to start_with("<wrap>")
      expect(html).to include("A POST WITHOUT FRONTMATTER")
    end
  end

  describe "global preprocessor" do
    it "replaces the default process_content for every entry" do
      Marquery.configure do |c|
        c.preprocessor = ->(raw, entry) { "[#{entry.slug}]\n#{raw}" }
      end

      html = query_class.new.find("second-post").to_html
      expect(html).to include("[second-post]")
    end
  end
end
