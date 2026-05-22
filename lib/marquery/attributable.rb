# frozen_string_literal: true

require "date"
require "time"

module Marquery
  module Attributable
    VALID_TYPES = %i[string int float bool date time array].freeze

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def attribute(name, type: nil, default: nil)
        validate_type!(type) if type

        name = name.to_sym
        attributes[name] = {type: type, default: deep_freeze(default)}
        attr_reader name

        alias_method("#{name}?", name) if type == :bool
      end

      def attributes
        @attributes ||= {}
      end

      private

      def validate_type!(type)
        return if VALID_TYPES.include?(type)

        raise ArgumentError,
              "Unknown attribute type: #{type.inspect} (expected one of #{VALID_TYPES.inspect})"
      end

      def deep_freeze(value)
        case value
        when Array then value.map { deep_freeze(_1) }.freeze
        when Hash then value.transform_values { deep_freeze(_1) }.freeze
        when String then value.frozen? ? value : value.dup.freeze
        else value
        end
      end
    end

    private

    def assign_declared_attributes(attrs)
      self.class.attributes.each do |name, config|
        raw = attrs.key?(name) ? attrs[name] : config[:default]
        value = config[:type] && !raw.nil? ? coerce_attribute(raw, config[:type]) : raw
        instance_variable_set(:"@#{name}", value)
      end
    end

    def coerce_attribute(value, type)
      case type
      when :string then value.to_s
      when :int then Integer(value)
      when :float then Float(value)
      when :bool then value == true || value == "true"
      when :date then value.is_a?(Date) ? value : Date.parse(value.to_s)
      when :time then value.is_a?(Time) ? value : Time.parse(value.to_s)
      when :array then Array(value)
      end
    end
  end
end
