# frozen_string_literal: true

require_relative "marquery/version"
require_relative "marquery/error"
require_relative "marquery/order"
require_relative "marquery/markdown_to_html"
require_relative "marquery/renderer"
require_relative "marquery/renderable"
require_relative "marquery/attributable"
require_relative "marquery/model"
require_relative "marquery/entry"
require_relative "marquery/collection"
require_relative "marquery/index"
require_relative "marquery/parser"
require_relative "marquery/registry"
require_relative "marquery/query"
require_relative "marquery/helpers"

module Marquery
  class Configuration
    attr_accessor :data_dir, :preprocessor

    def initialize
      @data_dir = "marquery"
      @preprocessor = nil
    end
  end

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
      config
    end

    def reset_config!
      @config = Configuration.new
    end

    def eager_load!
      Marquery::Registry.classes.each(&:load!)
    end
  end
end
