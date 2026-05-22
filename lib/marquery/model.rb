# frozen_string_literal: true

require_relative "attributable"
require_relative "renderable"

module Marquery
  module Model
    def self.included(base)
      base.include(Marquery::Renderable)
      base.include(Marquery::Attributable)
    end

    attr_reader :slug, :title, :description, :content, :date, :source

    def initialize(attrs = {})
      attrs = attrs.transform_keys(&:to_sym)
      assign_standard_attributes(attrs)
      assign_declared_attributes(attrs)
    end

    def active? = @active

    def ==(other)
      other.is_a?(self.class) && other.slug == slug
    end
    alias_method :eql?, :==

    def hash = [self.class, slug].hash

    def to_h
      {
        slug:,
        title:,
        description:,
        content:,
        date:,
        active: active?,
        source:,
        assets:
      }.tap do |base|
        self.class.attributes.each_key do |name|
          base[name] = public_send(name)
        end
      end
    end

    private

    def assign_standard_attributes(attrs)
      @slug = attrs.fetch(:slug)
      @title = attrs.fetch(:title)
      @description = attrs[:description]
      @content = attrs.fetch(:content, "")
      @date = attrs[:date]
      @active = attrs.fetch(:active, true)
      @source = attrs[:source]
      @assets = attrs.fetch(:assets, {})
    end
  end
end
