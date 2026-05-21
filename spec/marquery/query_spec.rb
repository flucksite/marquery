# frozen_string_literal: true

RSpec.describe Marquery::Query do
  let(:query_class) do
    Class.new do
      include Marquery::Query
      dir "blog_post"
    end
  end

  describe "class-level DSL" do
    it "uses Marquery::Entry by default" do
      expect(query_class.model).to eq(Marquery::Entry)
    end

    it "uses Marquery::Index by default" do
      expect(query_class.index).to eq(Marquery::Index)
    end

    it "defaults order_by to date desc" do
      expect(query_class.order_by).to eq([:date, Marquery::Order::DESC])
    end

    it "allows overriding the order direction" do
      klass = Class.new do
        include Marquery::Query
        dir "blog_post"
        order_by :title, :asc
      end

      expect(klass.order_by).to eq([:title, Marquery::Order::ASC])
    end

    it "derives the dir from the class name" do
      stub_const("Blog::PostQuery", Class.new { include Marquery::Query })
      expect(Blog::PostQuery.dir).to eq("blog_post")
    end

    it "computes data_path under the global data_dir" do
      expect(query_class.data_path).to eq("spec/fixtures/marquery/blog_post")
    end
  end

  describe "loading" do
    it "lazy-loads entries on first instantiation" do
      expect(query_class.loaded?).to be(false)
      query_class.new
      expect(query_class.loaded?).to be(true)
    end

    it "exposes the parsed index entry" do
      expect(query_class.index_entry.title).to eq("My Blog")
    end

    it "can be reloaded" do
      query_class.new
      expect(query_class.loaded?).to be(true)
      query_class.reload!
      expect(query_class.loaded?).to be(true)
    end
  end

  describe "instance API" do
    subject(:query) { query_class.new }

    it "returns all entries via #all" do
      expect(query.all.map(&:slug)).to contain_exactly(
        "first-post",
        "second-post",
        "inactive-post"
      )
    end

    it "exposes size, count, length" do
      expect(query.size).to eq(3)
      expect(query.count).to eq(3)
      expect(query.length).to eq(3)
    end

    it "finds by slug" do
      expect(query.find("first-post").slug).to eq("first-post")
    end

    it "raises EntryNotFound for missing slugs" do
      expect { query.find("nope") }.to raise_error(Marquery::EntryNotFound)
    end

    it "returns nil from find_by_slug for missing slugs" do
      expect(query.find_by_slug("nope")).to be_nil
    end

    it "filters into a new query" do
      filtered = query.filter(&:active?)
      expect(filtered).to be_a(query_class)
      expect(filtered.map(&:slug)).to contain_exactly("first-post", "second-post")
    end

    it "is immutable across chaining" do
      filtered = query.filter(&:active?)
      expect(query.size).to eq(3)
      expect(filtered.size).to eq(2)
    end

    it "sorts into a new query" do
      sorted = query.sort_by(&:slug)
      expect(sorted.map(&:slug)).to eq(%w[first-post inactive-post second-post])
      expect(query.map(&:slug)).not_to eq(sorted.map(&:slug))
    end

    it "reverses" do
      expect(query.reverse.first).to eq(query.last)
    end

    it "supports previous/next navigation" do
      ordered = query.sort_by(&:date)
      first = ordered.first
      second = ordered.all[1]
      expect(ordered.next(first)).to eq(second)
      expect(ordered.previous(second)).to eq(first)
      expect(ordered.previous(first)).to be_nil
      expect(ordered.next(ordered.last)).to be_nil
    end

    it "yields entries from #each" do
      slugs = []
      query.each { |entry| slugs << entry.slug }
      expect(slugs).to contain_exactly("first-post", "second-post", "inactive-post")
    end
  end

  describe "custom models" do
    let(:post_class) do
      Class.new do
        include Marquery::Model

        attribute :tags, type: :array, default: []
        attribute :author
      end
    end

    let(:custom_query) do
      klass = post_class
      Class.new do
        include Marquery::Query
        model klass
        dir "blog_post"
      end
    end

    it "populates declared attributes from frontmatter" do
      post = custom_query.new.find("first-post")
      expect(post.tags).to eq(%w[ruby markdown])
      expect(post.author).to eq("Wout")
    end
  end
end
