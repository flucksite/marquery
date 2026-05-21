# frozen_string_literal: true

require "marquery/asset_handler"
require "rack/mock"

RSpec.describe Marquery::AssetHandler do
  let(:downstream_response) { [404, {"content-type" => "text/plain"}, ["not found"]] }
  let(:downstream) { ->(_env) { downstream_response } }
  let(:root) { "spec/fixtures/marquery/blog_post" }
  let(:handler) { described_class.new(downstream, root) }

  def request(path)
    env = Rack::MockRequest.env_for(path)
    handler.call(env)
  end

  it "serves an existing asset" do
    status, headers, body = request("/spec/fixtures/marquery/blog_post/20260320_first_post/hero.png")

    expect(status).to eq(200)
    expect(headers["content-type"]).to eq("image/png")
    expect(headers["content-length"]).to eq(body.first.bytesize.to_s)
  end

  it "falls through when no file matches" do
    expect(request("/nonexistent")).to eq(downstream_response)
  end

  it "ignores the root path" do
    expect(request("/")).to eq(downstream_response)
  end

  it "rejects paths that escape the configured root via traversal" do
    expect(request("/spec/fixtures/marquery/blog_post/../../../Gemfile")).to eq(downstream_response)
  end

  it "rejects absolute paths outside the configured root" do
    expect(request("/etc/passwd")).to eq(downstream_response)
  end

  it "accepts multiple roots" do
    multi = described_class.new(downstream, "spec/fixtures", "lib")
    status, _, _ = multi.call(Rack::MockRequest.env_for("/lib/marquery.rb"))
    expect(status).to eq(200)
  end

  it "skips non-existent directories silently" do
    described_class.new(downstream, "does/not/exist")
  end
end
