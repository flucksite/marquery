# frozen_string_literal: true

module Marquery
  module MarkdownToHtml
    def markdown_to_html(_content)
      raise NotImplementedError, "#{self.class} must implement #markdown_to_html"
    end
  end
end
