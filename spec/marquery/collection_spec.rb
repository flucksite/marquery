# frozen_string_literal: true

RSpec.describe Marquery::Collection do
  let(:collection_class) do
    Class.new do
      include Marquery::Collection

      attribute :subtitle
      attribute :featured_slugs, type: :array, default: []
    end
  end

  it "exposes standard readers with defaults" do
    instance = collection_class.new
    expect(instance.title).to eq("")
    expect(instance.description).to be_nil
    expect(instance.content).to eq("")
    expect(instance.subtitle).to be_nil
    expect(instance.featured_slugs).to eq([])
  end

  it "populates declared attributes from the input hash" do
    instance = collection_class.new(
      title: "Blog",
      description: "Thoughts",
      content: "Hello",
      subtitle: "Ruby and Hanami",
      featured_slugs: %w[first-post third-post]
    )

    expect(instance.subtitle).to eq("Ruby and Hanami")
    expect(instance.featured_slugs).to eq(%w[first-post third-post])
  end

  it "returns the full hash via to_h" do
    instance = collection_class.new(title: "Blog", subtitle: "Subtitle")
    expect(instance.to_h).to include(
      title: "Blog",
      subtitle: "Subtitle",
      featured_slugs: []
    )
  end
end
