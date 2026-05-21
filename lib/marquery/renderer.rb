# frozen_string_literal: true

require "commonmarker"

require_relative "markdown_to_html"

module Marquery
  class Renderer
    include MarkdownToHtml

    DEFAULT_OPTIONS = {
      parse: {smart: true},
      render: {unsafe: true, github_pre_lang: true},
      extension: {
        strikethrough: true,
        table: true,
        autolink: true,
        tagfilter: true,
        tasklist: true,
        footnotes: true
      }
    }.freeze

    def markdown_to_html(content)
      Commonmarker.to_html(content.strip, options: DEFAULT_OPTIONS)
    end
  end
end
