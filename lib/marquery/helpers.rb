# frozen_string_literal: true

require_relative "renderable"
require_relative "renderer"

module Marquery
  module Helpers
    extend self

    def markdown(content, renderer: Marquery::Renderer)
      case content
      when nil
        ""
      when Marquery::Renderable
        content.to_html
      when String
        renderer.new.markdown_to_html(content)
      else
        raise(
          ArgumentError,
          "markdown expects a String, nil, or Marquery::Renderable, got #{content.class}"
        )
      end
    end
  end
end
