# frozen_string_literal: true

require "date"
require "pathname"
require "time"
require "yaml"

require_relative "error"
require_relative "order"

module Marquery
  class Parser
    DATE_REGEX = /\A(?<date>\d{8})_(?<name>[^.]+)/
    CONTENT_REGEX = /\A(?:---\n(?<frontmatter>.*?)\n---\n)?(?<body>.*)\z/m
    ASSET_EXTENSIONS = %w[.avif .gif .jpeg .jpg .mp3 .mp4 .ogg .pdf .png .svg .webm .webp].freeze
    PERMITTED_YAML_CLASSES = [Date, Time, Symbol].freeze

    Result = Struct.new(:index, :entries, keyword_init: true)

    def initialize(dir:, model:, index:, order_by:, assets_dir: nil)
      @dir = Pathname.new(dir.to_s)
      @assets_dir = assets_dir ? Pathname.new(assets_dir.to_s) : nil
      @model = model
      @index = index
      @order_field, @order_direction = order_by
    end

    def call
      Result.new(index: load_index, entries: sort(load_entries))
    end

    private

    def load_index
      file = @dir.join("_index.md")
      return @index.new unless file.file?

      match = match_content(file.read)
      attrs = {
        content: match[:body].to_s.strip,
        assets: collect_assets(@dir.join("_index"))
      }
      attrs.merge!(parse_frontmatter(match[:frontmatter]))
      @index.new(**attrs)
    end

    def load_entries
      return [] unless @dir.directory?

      Pathname
        .glob(@dir.join("*.md"))
        .reject { _1.basename.to_s == "_index.md" }
        .map { load_entry(_1) }
    end

    def load_entry(path)
      basename = path.basename.to_s
      unless filename_match = basename.match(DATE_REGEX)
        raise Marquery::ParseError, "Invalid filename: #{path}"
      end

      name = filename_match[:name]
      date_str = filename_match[:date]
      content_match = match_content(path.read)

      attrs = {
        slug: parameterize(name),
        title: humanize(name),
        date: parse_date(date_str),
        source: path.to_s,
        content: content_match[:body].to_s.strip,
        assets: assets_for(path, date_str)
      }
      attrs.merge!(parse_frontmatter(content_match[:frontmatter]))
      @model.new(**attrs)
    end

    def assets_for(path, date_str)
      hash = {}
      if @assets_dir
        hash.merge!(collect_assets(@assets_dir.join("_shared")))
        hash.merge!(collect_assets(@assets_dir.join(date_str)))
      end
      hash.merge!(collect_assets(Pathname.new(path.to_s.sub(/\.md\z/, ""))))
      hash
    end

    def collect_assets(dir)
      return {} unless dir.directory?

      dir.children.sort.each_with_object({}) do |child, memo|
        basename = child.basename.to_s
        next if basename.start_with?(".")
        next if child.directory?
        next unless ASSET_EXTENSIONS.include?(child.extname.downcase)

        memo[basename] = child.to_s.delete_prefix("./")
      end
    end

    def match_content(text)
      match = text.match(CONTENT_REGEX)
      raise Marquery::ParseError, "Unable to parse content" unless match

      {frontmatter: match[:frontmatter], body: match[:body]}
    end

    def parse_frontmatter(text)
      return {} if text.nil? || text.strip.empty?

      parsed = YAML.safe_load(text, permitted_classes: PERMITTED_YAML_CLASSES, aliases: false)
      raise Marquery::ParseError, "Frontmatter must be a YAML mapping" unless parsed.is_a?(Hash)

      parsed.transform_keys(&:to_sym)
    end

    def parse_date(date_str)
      Time.strptime(date_str, "%Y%m%d")
    rescue ArgumentError => exception
      raise Marquery::ParseError, "Invalid date prefix #{date_str.inspect}: #{exception.message}"
    end

    def sort(entries)
      sorted = entries.sort_by { _1.public_send(@order_field) }
      @order_direction == Marquery::Order::DESC ? sorted.reverse : sorted
    end

    def parameterize(str)
      str
        .tr("_", "-")
        .downcase
        .gsub(/[^a-z0-9-]/, "")
        .squeeze("-")
        .gsub(/\A-|-\z/, "")
    end

    def humanize(str)
      cleaned = str.tr("_", " ").tr("-", " ").gsub(/\s+/, " ").strip
      return cleaned if cleaned.empty?

      cleaned[0].upcase + cleaned[1..]
    end
  end
end
