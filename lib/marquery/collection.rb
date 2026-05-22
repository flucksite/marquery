# frozen_string_literal: true

require_relative "attributable"
require_relative "renderable"

module Marquery
  module Collection
    def self.included(base)
      base.include(Marquery::Renderable)
      base.include(Marquery::Attributable)
    end

    attr_reader :title, :description, :content

    def initialize(attrs = {})
      attrs = attrs.transform_keys(&:to_sym)
      assign_standard_attributes(attrs)
      assign_declared_attributes(attrs)
    end

    def to_h
      {title:, description:, content:, assets:}.tap do |base|
        self.class.attributes.each_key do |name|
          base[name] = public_send(name)
        end
      end
    end

    private

    def assign_standard_attributes(attrs)
      @title = attrs.fetch(:title, "")
      @description = attrs[:description]
      @content = attrs.fetch(:content, "")
      @assets = attrs.fetch(:assets, {})
    end
  end
end
