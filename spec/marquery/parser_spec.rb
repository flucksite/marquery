# frozen_string_literal: true

require "tmpdir"

RSpec.describe Marquery::Parser do
  let(:parser) do
    described_class.new(
      dir: "spec/fixtures/marquery/blog_post",
      model: Marquery::Entry,
      index: Marquery::Index,
      order_by: [:date, Marquery::Order::DESC]
    )
  end
  let(:result) { parser.call }

  describe "#call" do
    it "returns a Result with index and entries" do
      expect(result.index).to be_a(Marquery::Index)
      expect(result.entries).to all(be_a(Marquery::Entry))
    end

    it "loads the index from _index.md" do
      expect(result.index.title).to eq("My Blog")
      expect(result.index.description).to eq("Posts about software")
      expect(result.index.content).to eq("Welcome to my blog.")
    end

    it "parses entries with frontmatter" do
      first = result.entries.find { |e| e.slug == "first-post" }
      expect(first.title).to eq("First post")
      expect(first.description).to eq("An introductory post")
      expect(first.date).to eq(Time.strptime("20260320", "%Y%m%d"))
      expect(first.active?).to be(true)
    end

    it "parses entries without frontmatter" do
      second = result.entries.find { |e| e.slug == "second-post" }
      expect(second.title).to eq("Second post")
      expect(second.description).to be_nil
      expect(second.content).to start_with("A post without frontmatter.")
    end

    it "honors active: false in frontmatter" do
      inactive = result.entries.find { |e| e.slug == "inactive-post" }
      expect(inactive.active?).to be(false)
    end

    it "collects assets in sibling directories" do
      first = result.entries.find { |e| e.slug == "first-post" }
      expect(first.assets).to include("hero.png")
      expect(first.assets["hero.png"]).to end_with("blog_post/20260320_first_post/hero.png")
    end

    it "sorts entries by date descending by default" do
      dates = result.entries.map(&:date)
      expect(dates).to eq(dates.sort.reverse)
    end

    it "sorts entries ascending when requested" do
      ascending = described_class.new(
        dir: "spec/fixtures/marquery/blog_post",
        model: Marquery::Entry,
        index: Marquery::Index,
        order_by: [:date, Marquery::Order::ASC]
      ).call

      dates = ascending.entries.map(&:date)
      expect(dates).to eq(dates.sort)
    end
  end

  describe "filename parsing" do
    it "raises on invalid filenames" do
      Dir.mktmpdir do |tmp|
        File.write(File.join(tmp, "no_date_prefix.md"), "body")

        bad = described_class.new(
          dir: tmp,
          model: Marquery::Entry,
          index: Marquery::Index,
          order_by: [:date, Marquery::Order::DESC]
        )

        expect { bad.call }.to raise_error(Marquery::ParseError, /Invalid filename/)
      end
    end
  end

  describe "frontmatter parsing" do
    it "raises ParseError when frontmatter is a YAML scalar instead of a mapping" do
      Dir.mktmpdir do |tmp|
        File.write(
          File.join(tmp, "20260320_post.md"),
          "---\njust a string scalar\n---\nbody\n"
        )

        bad = described_class.new(
          dir: tmp,
          model: Marquery::Entry,
          index: Marquery::Index,
          order_by: [:date, Marquery::Order::DESC]
        )

        expect { bad.call }
          .to raise_error(Marquery::ParseError, /Frontmatter must be a YAML mapping/)
      end
    end

    it "raises ParseError for an unparseable date prefix" do
      Dir.mktmpdir do |tmp|
        File.write(File.join(tmp, "20269999_post.md"), "body")

        bad = described_class.new(
          dir: tmp,
          model: Marquery::Entry,
          index: Marquery::Index,
          order_by: [:date, Marquery::Order::DESC]
        )

        expect { bad.call }
          .to raise_error(Marquery::ParseError, /Invalid date prefix/)
      end
    end
  end
end
