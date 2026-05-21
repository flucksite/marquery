# frozen_string_literal: true

require_relative "entry"
require_relative "index"
require_relative "order"
require_relative "parser"
require_relative "registry"

module Marquery
  module Query
    include Enumerable

    def self.included(base)
      base.extend(ClassMethods)
      Marquery::Registry.register(base)
    end

    module ClassMethods
      def model(klass = nil)
        @marquery_model = klass if klass
        @marquery_model ||= Marquery::Entry
      end

      def index(klass = nil)
        @marquery_index = klass if klass
        @marquery_index ||= Marquery::Index
      end

      def order_by(field = nil, direction = nil)
        if field
          @order_field = field.to_sym
          @order_direction = direction ? Marquery::Order.validate!(direction) : Marquery::Order::DESC
        end
        [@order_field || :date, @order_direction || Marquery::Order::DESC]
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

      def loaded?
        !!(defined?(@loaded) && @loaded)
      end

      def load!
        @marquery_data = Marquery::Parser.new(
          dir: data_path,
          assets_dir: assets_dir,
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
        name
          .to_s
          .sub(/Query\z/, "")
          .gsub("::", "")
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
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

    def all
      entries
    end

    def size
      entries.size
    end
    alias_method :length, :size
    alias_method :count, :size

    def empty?
      entries.empty?
    end

    def first
      entries.first
    end

    def last
      entries.last
    end

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
