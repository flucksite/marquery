# frozen_string_literal: true

require_relative "renderer"

module Marquery
  ASSET_URI_REGEX = %r{asset:([^\s)"'<>]+)}

  module Renderable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def renderer(klass = nil)
        if klass
          @marquery_renderer = klass
          return klass
        end

        return @marquery_renderer if defined?(@marquery_renderer) && @marquery_renderer
        return superclass.renderer if superclass.respond_to?(:renderer)

        Marquery::Renderer
      end
    end

    def assets
      @assets ||= {}
    end

    def asset(name)
      path = assets[name] || raise(Marquery::AssetNotFound.new(name))
      "/#{path}"
    end

    def asset?(name)
      path = assets[name]
      path && "/#{path}"
    end

    def rewrite_assets(raw)
      raw.gsub(Marquery::ASSET_URI_REGEX) { asset(::Regexp.last_match(1)) }
    end

    def process_content(raw)
      preprocessor = Marquery.config.preprocessor
      return preprocessor.call(raw, self) if preprocessor

      rewrite_assets(raw)
    end

    def to_html
      self.class.renderer.new.markdown_to_html(process_content(content))
    end
  end
end
