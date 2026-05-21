# frozen_string_literal: true

require "rack"
require "rack/mime"

module Marquery
  class AssetHandler
    def initialize(app, *directories)
      @app = app
      @roots = directories.flatten.compact.map { resolve_root(_1) }.compact
    end

    def call(env)
      path = env["PATH_INFO"].to_s
      if (resolved = serveable_path(path))
        serve_file(resolved)
      else
        @app.call(env)
      end
    end

    private

    def resolve_root(dir)
      expanded = File.expand_path(dir.to_s)
      return nil unless File.directory?(expanded)

      File.realpath(expanded)
    end

    def serveable_path(request_path)
      return nil if request_path.nil? || request_path.empty?

      stripped = request_path.sub(%r{\A/}, "")
      return nil if stripped.empty?
      return nil unless File.file?(stripped)

      real = File.realpath(stripped)
      contained?(real) ? real : nil
    rescue Errno::ENOENT, Errno::ENAMETOOLONG, Errno::EACCES
      nil
    end

    def contained?(real_path)
      @roots.any? do |root|
        real_path == root || real_path.start_with?(root + File::SEPARATOR)
      end
    end

    def serve_file(path)
      mime = Rack::Mime.mime_type(File.extname(path), "application/octet-stream")
      body = File.binread(path)
      headers = {
        "content-type" => mime,
        "content-length" => body.bytesize.to_s
      }
      [200, headers, [body]]
    end
  end
end
