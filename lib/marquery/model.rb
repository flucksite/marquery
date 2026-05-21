# frozen_string_literal: true

require "date"
require "time"

require_relative "renderable"

module Marquery
  module Model
    def self.included(base)
      base.include(Marquery::Renderable)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def attribute(name, type: nil, default: nil)
        name = name.to_sym
        attributes[name] = {type: type, default: deep_freeze(default)}
        attr_reader name

        alias_method("#{name}?", name) if type == :bool
      end

      def attributes
        @attributes ||= {}
      end

      private

      def deep_freeze(value)
        case value
        when Array then value.map { deep_freeze(_1) }.freeze
        when Hash then value.transform_values { deep_freeze(_1) }.freeze
        when String then value.frozen? ? value : value.dup.freeze
        else value
        end
      end
    end

    attr_reader :slug, :title, :description, :content, :date, :source

    def initialize(attrs = {})
      attrs = attrs.transform_keys(&:to_sym)
      assign_standard_attributes(attrs)
      assign_declared_attributes(attrs)
    end

    def active?
      @active
    end

    def ==(other)
      other.is_a?(self.class) && other.slug == slug
    end
    alias_method :eql?, :==

    def hash
      [self.class, slug].hash
    end

    def to_h
      base = {
        slug: slug,
        title: title,
        description: description,
        content: content,
        date: date,
        active: active?,
        source: source,
        assets: assets
      }
      self.class.attributes.each_key do |name|
        base[name] = public_send(name)
      end
      base
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

    def assign_declared_attributes(attrs)
      self.class.attributes.each do |name, config|
        raw = attrs.key?(name) ? attrs[name] : config[:default]
        value = config[:type] && !raw.nil? ? coerce(raw, config[:type]) : raw
        instance_variable_set(:"@#{name}", value)
      end
    end

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
