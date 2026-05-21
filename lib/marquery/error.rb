# frozen_string_literal: true

module Marquery
  class Error < StandardError; end

  class EntryNotFound < Error
    def initialize(slug)
      super("Entry not found: #{slug}")
    end
  end

  class AssetNotFound < Error
    def initialize(name)
      super("Asset not found: #{name}")
    end
  end

  class ParseError < Error; end
end
