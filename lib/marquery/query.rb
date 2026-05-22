# frozen_string_literal: true

require "forwardable"
require_relative "entry"
require_relative "index"
require_relative "order"
require_relative "parser"
require_relative "registry"

module Marquery
  module Query
    extend Forwardable
    include Enumerable

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@marquery_model, Marquery::Entry)
      base.instance_variable_set(:@marquery_index, Marquery::Index)
      base.instance_variable_set(:@order_field, :date)
      base.instance_variable_set(:@order_direction, Marquery::Order::DESC)
      base.instance_variable_set(:@dir, nil)
      base.instance_variable_set(:@assets_dir, nil)
      base.instance_variable_set(:@marquery_data, nil)
      base.instance_variable_set(:@loaded, false)
      Marquery::Registry.register(base)
    end

    module ClassMethods
      def model(klass = nil)
        @marquery_model = klass if klass
        @marquery_model
      end

      def index(klass = nil)
        @marquery_index = klass if klass
        @marquery_index
      end

      def order_by(field = nil, direction = nil)
        if field
          @order_field = field.to_sym
          @order_direction = Marquery::Order.validate!(direction) if direction
        end
        [@order_field, @order_direction]
      end

      def dir(path = nil)
        @dir = path.to_s if path
        @dir ||= derive_dir
      end

      def assets_dir(path = nil)
        @assets_dir = path.to_s unless path.nil?
        @assets_dir
      end

      def data_path
        File.join(Marquery.config.data_dir, dir)
      end

      def assets_path
        return nil unless assets_dir

        File.join(Marquery.config.data_dir, assets_dir)
      end

      def loaded?
        @loaded
      end

      def load!
        @marquery_data = Marquery::Parser.new(
          dir: data_path,
          assets_dir: assets_path,
          model: model,
          index: index,
          order_by: order_by
        ).call
        @loaded = true
        self
      end

      def reload!
        @loaded = false
        @marquery_data = nil
        load!
      end

      def all_entries
        load! unless loaded?
        @marquery_data.entries
      end

      def index_entry
        load! unless loaded?
        @marquery_data.index
      end

      private

      def derive_dir
        derived = name
          .to_s
          .sub(/Query\z/, "")
          .gsub("::", "")
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase

        return derived unless derived.empty?

        raise(
          Marquery::Error,
          "Cannot derive directory for #{inspect}; call `dir \"...\"` explicitly"
        )
      end
    end

    attr_reader :entries

    def initialize(entries = nil)
      @entries = (entries || self.class.all_entries).freeze
    end

    def each(&block)
      return enum_for(:each) unless block

      entries.each(&block)
      self
    end

    def all = entries

    def_delegators :entries, :size, :length, :count, :empty?, :first, :last

    def find(slug)
      find_by_slug(slug) || raise(Marquery::EntryNotFound.new(slug))
    end

    def find_by_slug(slug)
      entries.find { |entry| entry.slug == slug }
    end

    def filter(&block)
      return self unless block

      new_query(entries.select(&block))
    end
    alias_method :select, :filter

    def reject(&block)
      return self unless block

      new_query(entries.reject(&block))
    end

    def sort_by(&block)
      new_query(entries.sort_by(&block))
    end

    def reverse
      new_query(entries.reverse)
    end

    def shuffle(random: Random.new)
      new_query(entries.shuffle(random: random))
    end

    def previous(entry)
      idx = entries.index(entry)
      return nil if idx.nil? || idx.zero?

      entries[idx - 1]
    end

    def next(entry)
      idx = entries.index(entry)
      return nil if idx.nil?

      entries[idx + 1]
    end

    private

    def new_query(new_entries)
      self.class.new(new_entries)
    end
  end
end
