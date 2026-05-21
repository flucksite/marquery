# frozen_string_literal: true

require_relative "renderable"
require_relative "model"

module Marquery
  module Collection
    def self.included(base)
      base.include(Marquery::Renderable)
      base.extend(Marquery::Model::ClassMethods)
    end

    attr_reader :title, :description, :content

    def initialize(attrs = {})
      attrs = attrs.transform_keys(&:to_sym)

      @title = attrs.fetch(:title, "")
      @description = attrs[:description]
      @content = attrs.fetch(:content, "")
      @assets = attrs.fetch(:assets, {})

      self.class.attributes.each do |name, config|
        raw = attrs.key?(name) ? attrs[name] : config[:default]
        value = config[:type] && !raw.nil? ? coerce(raw, config[:type]) : raw
        instance_variable_set(:"@#{name}", value)
      end
    end

    def to_h
      base = {
        title: title,
        description: description,
        content: content,
        assets: @assets
      }
      self.class.attributes.each_key do |name|
        base[name] = public_send(name)
      end
      base
    end

    private

    def coerce(value, type)
      case type
      when :string then value.to_s
      when :int then Integer(value)
      when :float then Float(value)
      when :bool then value == true || value == "true"
      when :date then value.is_a?(Date) ? value : Date.parse(value.to_s)
      when :time then value.is_a?(Time) ? value : Time.parse(value.to_s)
      when :array then Array(value)
      else value
      end
    end
  end
end
