# frozen_string_literal: true

RSpec.describe Marquery::Model do
  let(:model_class) do
    Class.new do
      include Marquery::Model

      attribute :tags, type: :array, default: []
      attribute :author
      attribute :rating, type: :int
      attribute :featured, type: :bool, default: false
      attribute :published_on, type: :date
    end
  end

  it "exposes standard readers" do
    entry = model_class.new(
      slug: "post",
      title: "A Post",
      content: "body",
      date: Time.now
    )

    expect(entry.slug).to eq("post")
    expect(entry.title).to eq("A Post")
    expect(entry.content).to eq("body")
    expect(entry.active?).to be(true)
  end

  it "applies declared attributes" do
    entry = model_class.new(
      slug: "post",
      title: "A Post",
      tags: %w[ruby gem],
      author: "Wout",
      rating: "5",
      featured: "true",
      published_on: "2026-05-21"
    )

    expect(entry.tags).to eq(%w[ruby gem])
    expect(entry.author).to eq("Wout")
    expect(entry.rating).to eq(5)
    expect(entry.featured?).to be(true)
    expect(entry.published_on).to eq(Date.new(2026, 5, 21))
  end

  it "uses declared defaults when frontmatter is missing" do
    entry = model_class.new(slug: "post", title: "A Post")

    expect(entry.tags).to eq([])
    expect(entry.featured?).to be(false)
    expect(entry.author).to be_nil
  end

  it "defines question-mark predicates for bool attributes" do
    expect(model_class.instance_method(:featured?)).to be_a(UnboundMethod)
  end

  it "considers two entries equal when slug and class match" do
    a = model_class.new(slug: "post", title: "A")
    b = model_class.new(slug: "post", title: "B")
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  describe "#to_h" do
    it "returns standard and declared attributes" do
      entry = model_class.new(
        slug: "post",
        title: "A Post",
        description: "x",
        content: "body",
        tags: %w[ruby gem],
        author: "Wout",
        featured: true
      )

      expect(entry.to_h).to include(
        slug: "post",
        title: "A Post",
        description: "x",
        content: "body",
        active: true,
        tags: %w[ruby gem],
        author: "Wout",
        featured: true
      )
    end
  end
end
