# frozen_string_literal: true

module Marquery
  module Order
    ASC = :asc
    DESC = :desc

    VALID = [ASC, DESC].freeze

    def self.validate!(value)
      return value if VALID.include?(value)

      raise ArgumentError, "Invalid order: #{value.inspect} (expected :asc or :desc)"
    end
  end
end
