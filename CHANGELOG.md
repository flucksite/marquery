# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial scaffolding inspired by the
  [Crystal marquery shard](https://codeberg.org/fluck/marquery.cr).
- `Marquery::Model` with standard fields (`slug`, `title`, `description`,
  `content`, `date`, `active?`, `source`, `assets`) and an `attribute` DSL
  for declaring frontmatter-backed fields with optional type coercion.
- `Marquery::Entry` as the default model.
- `Marquery::Collection` and `Marquery::Index` for `_index.md` metadata,
  including the same `attribute` DSL for custom index types.
- `Marquery::Renderable` with `assets`, `asset`, `asset?`, `rewrite_assets`,
  `process_content`, `to_html`, and a per-class `renderer` DSL.
- `Marquery::Renderer` defaulting to Commonmarker (GitHub Flavored Markdown).
- `Marquery::MarkdownToHtml` interface for plugging in alternative
  markdown libraries.
- `Marquery::Query` with class-level DSL (`model`, `index`, `order_by`,
  `dir`, `assets_dir`) and a chainable, immutable instance API
  (`all`, `find`, `find_by_slug`, `filter`, `reject`, `sort_by`, `reverse`,
  `shuffle`, `previous`, `next`, `first`, `last`, `size`). Queries include
  `Enumerable`.
- `Marquery::Parser` for loading entries and `_index.md` at runtime with
  YAML frontmatter and asset directories (per-entry plus `_shared` and
  dated directories under a shared `assets_dir`).
- `Marquery::Registry` and `Marquery.eager_load!` for opt-in warmup at
  boot.
- `Marquery::Configuration` accessed via `Marquery.configure` block, with
  `data_dir` and `preprocessor` keys.
- `Marquery::Helpers` module exposing `markdown(content)` for use from
  view helpers in Hanami, Rails, or any Ruby class.
- `Marquery::AssetHandler` Rack middleware with multi-root support and
  path-traversal protection (opt-in via `require "marquery/asset_handler"`).
- `to_h` on `Marquery::Model` and `Marquery::Collection` returning the
  full attribute hash.
- `Marquery::Error`, `Marquery::EntryNotFound`, `Marquery::AssetNotFound`,
  and `Marquery::ParseError` exception types.
- Codeberg / Forgejo CI workflow running rspec and rubocop on Ruby 3.4
  and 4.0.
- README covering quickstart, queries, error handling, configuration,
  custom index models, custom rendering, preprocessing, shared and
  multi-language assets, framework integration for Hanami / any Ruby app
  / Rails, pagination, and entry serialization.
