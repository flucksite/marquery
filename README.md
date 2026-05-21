# Marquery

A markdown query engine for Ruby. Load markdown files with YAML frontmatter
from a conventional directory layout, query them through a chainable API,
resolve associated assets, and render content to HTML.

This is a Ruby companion to the [Crystal marquery
shard](https://codeberg.org/fluck/marquery.cr). The Crystal version embeds
everything at compile time via macros; the Ruby version does the equivalent
work at runtime with memoization and an opt-in eager-load hook for production
boot.

> [!Note]
> The original repository is hosted at
> [Codeberg](https://codeberg.org/fluck/marquery). The [GitHub
> repo](https://github.com/flucksite/marquery) is just a mirror.

## Installation

Add this to your Gemfile:

```ruby
gem "marquery"
```

Then run `bundle install`. Ruby 3.2 or newer is required.

## Quickstart

### 1. Lay out your content

```
marquery/
  blog_post/
    _index.md
    20260320_first_post.md
    20260320_first_post/
      hero.png
    20260325_second_post.md
```

The directory name (`blog_post`) is derived from your query class name.
Filenames must start with a `YYYYMMDD_` date prefix.

### 2. Define a model (optional)

```ruby
class Post
  include Marquery::Model

  attribute :tags, type: :array, default: []
  attribute :author
  attribute :featured, type: :bool, default: false
end
```

If you do not declare a model, `Marquery::Entry` is used as a default. Standard
fields are always available: `slug`, `title`, `description`, `content`, `date`,
`active?`, `source`, `assets`.

### 3. Define a query

```ruby
class PostQuery
  include Marquery::Query

  model Post
  order_by :date, :desc
end
```

### 4. Query and render

```ruby
PostQuery.new.all
PostQuery.new.find("first-post")
PostQuery.new.filter(&:active?).sort_by(&:title).first
PostQuery.index_entry            # _index.md as a Marquery::Index

post = PostQuery.new.find("first-post")
post.to_html
post.asset("hero.png")
```

Chainable methods return new query instances, so chains are safe to reuse:

```ruby
recent = PostQuery.new.filter(&:active?)
recent.size                      # unaffected by later chaining
recent.sort_by(&:title).first    # returns the first by title
```

## Queries

Every filter or sort method returns a new query, so chains never mutate the
original.

```ruby
query = PostQuery.new

query.all                        # Array of entries
query.first                      # nil if empty
query.last                       # nil if empty
query.size                       # entry count

query.find("first-post")         # raises Marquery::EntryNotFound when missing
query.find_by_slug("first-post") # returns nil when missing

query.previous(post)             # previous entry, or nil at the start
query.next(post)                 # next entry, or nil at the end
```

Chainable methods, all returning a new query:

```ruby
query.filter(&:active?)
query.reject(&:active?)
query.sort_by(&:title)
query.reverse
query.shuffle
query.shuffle(random: Random.new(42))
```

`Marquery::Query` includes `Enumerable`, so `each`, `map`, `count`, `any?`,
`take`, and friends are available. Those return plain Arrays, matching
`Enumerable` conventions. Use the chainable methods above when you want to
keep working with a query.

### Error handling

Marquery raises typed exceptions that all inherit from `Marquery::Error`:

```ruby
begin
  PostQuery.new.find("nonexistent")
rescue Marquery::EntryNotFound => exception
  exception.message # => "Entry not found: nonexistent"
end

begin
  post.asset("missing.png")
rescue Marquery::AssetNotFound => exception
  exception.message # => "Asset not found: missing.png"
end
```

`Marquery::ParseError` is raised at load time when frontmatter or filenames
cannot be parsed. Catching `Marquery::Error` picks up all three.

## Configuration

```ruby
Marquery.configure do |c|
  c.data_dir = "content"
  c.preprocessor = ->(raw, entry) do
    Liquid::Template.parse(raw).render("entry" => entry)
  end
end
```

### Eager loading in production

```ruby
# config/initializers/marquery.rb (Rails)
Marquery.eager_load!
```

This walks every registered query class and parses files upfront so the first
request does not pay the loading cost.

## Custom index model

By default the `_index.md` file is parsed into a `Marquery::Index` with
the standard `title`, `description`, and `content` fields. For extra
metadata on the index page, define your own type that includes
`Marquery::Collection` and declare attributes the same way as on a model:

```ruby
class PostIndex
  include Marquery::Collection

  attribute :subtitle
  attribute :featured_slugs, type: :array, default: []
end

class PostQuery
  include Marquery::Query

  index PostIndex
end
```

```markdown
---
title: Blog
subtitle: Thoughts on Ruby and Hanami
featured_slugs:
  - first-post
  - third-post
---

Welcome to the blog.
```

```ruby
PostQuery.index_entry.subtitle        # => "Thoughts on Ruby and Hanami"
PostQuery.index_entry.featured_slugs  # => ["first-post", "third-post"]
PostQuery.index_entry.to_html         # => "<p>Welcome to the blog.</p>\n"
```

If no `_index.md` exists, `index_entry` returns an empty `Marquery::Index`
(or your custom collection) with default field values.

## Custom rendering

The default renderer uses
[commonmarker](https://github.com/gjtorikian/commonmarker) for GitHub-flavored
markdown. Swap it out per model:

```ruby
class MyRenderer
  include Marquery::MarkdownToHtml

  def markdown_to_html(content)
    Kramdown::Document.new(content).to_html
  end
end

class Post
  include Marquery::Model
  renderer MyRenderer
end
```

## Preprocessing

Two hooks, with per-model winning over global:

```ruby
# Global default.
Marquery.configure do |c|
  c.preprocessor = ->(raw, entry) { ... }
end

# Per-model override.
class Post
  include Marquery::Model

  def process_content(raw)
    rendered = Liquid::Template.parse(raw).render("entry" => self)
    rewrite_assets(rendered)
  end
end
```

If you override `process_content`, you are in charge of asset rewriting. Call
`rewrite_assets(content)` to opt back in.

## Shared and multi-language assets

For multilingual sites, point several query classes at a shared assets
directory. Each language gets its own content tree; assets live once.

```ruby
class Blog::EnQuery
  include Marquery::Query
  dir "blog_en"
  assets_dir "blog_assets"
end

class Blog::NlQuery
  include Marquery::Query
  dir "blog_nl"
  assets_dir "blog_assets"
end
```

Both `dir` and `assets_dir` resolve under `Marquery.config.data_dir` (default
`marquery/`). The example above looks at:

```
marquery/blog_en/         # English entries
marquery/blog_nl/         # Dutch entries
marquery/blog_assets/     # shared assets
├── _shared/
│   └── logo.svg          # available on every entry
├── 20260320/
│   └── hero.png          # available on entries dated 20260320
└── 20260325/
    └── diagram.svg
```

Assets merge in three layers, each overriding the previous one when keys
collide:

1. `_shared/` (available to every entry)
2. `<YYYYMMDD>/` (available to entries with that date prefix)
3. The per-entry sibling directory next to the markdown file

So a per-entry `banner.png` wins over a date-scoped `banner.png`, which in
turn wins over a `_shared/banner.png`. This lets you provide sensible
defaults and override per-entry when needed.

## Framework integration

Marquery ships two opt-in pieces for integrating with web frameworks:

- `Marquery::Helpers` exposes a `markdown(content)` method that accepts a
  String or any `Marquery::Renderable` (model or collection instance).
- `Marquery::AssetHandler` is Rack middleware that serves files from one or
  more marquery data directories with path-traversal protection.

The two snippets below are everything you need. The framework-specific sections
after them only differ in where you wire them up.

```ruby
# Renders a String or a Marquery::Renderable instance to HTML.
Marquery::Helpers.markdown(post)             # => "<h1>...</h1>"
Marquery::Helpers.markdown("# Hello")        # => "<h1>...</h1>"
Marquery::Helpers.markdown(post, renderer: MyRenderer)
```

```ruby
require "marquery/asset_handler"

# Rack middleware. Pass one or more directories to serve files from.
use Marquery::AssetHandler, "marquery/blog_post"
```

### Hanami

Include `Marquery::Helpers` in your slice's view helpers and mount the asset
handler as middleware. Both Hanami's app config and route-scoped middleware
work; pick whichever fits your slice layout.

```ruby
# app/views/helpers.rb
module MyApp
  module Views
    module Helpers
      include Marquery::Helpers
    end
  end
end
```

```ruby
# config/app.rb
require "marquery/asset_handler"

module MyApp
  class App < Hanami::App
    config.middleware.use Marquery::AssetHandler, "marquery/blog_post"
  end
end
```

In templates, mark the output as safe HTML with Hanami's `raw` helper:

```erb
<%= raw markdown(post) %>
```

### Any Ruby app

`Marquery::Helpers` is a plain module. `extend` it on the object that needs
the helper, or include it in a class.

```ruby
class PostPresenter
  include Marquery::Helpers

  def initialize(post)
    @post = post
  end

  def html
    markdown(@post)
  end
end
```

If you serve HTTP through Rack (Sinatra, Roda, plain Rack), mount the asset
handler in `config.ru`:

```ruby
require "marquery/asset_handler"

use Marquery::AssetHandler, "marquery/blog_post"
run MyApp
```

### Rails

Mix `Marquery::Helpers` into `ApplicationHelper` so `markdown` is available
across views.

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  include Marquery::Helpers
end
```

```erb
<%= raw markdown(@post) %>
```

For serving assets, either copy `marquery/` under `public/`, point Propshaft
at it, or add the Rack middleware:

```ruby
# config/application.rb
require "marquery/asset_handler"

config.middleware.use Marquery::AssetHandler, "marquery/blog_post"
```

### Pagination

`query.all` returns a plain Array, so any pagination library that takes an
Array works.

[Pagy](https://github.com/ddnexus/pagy) is the lightest option and works in
Hanami, Rails, Sinatra, Roda, and plain Rack:

```ruby
@pagy, @posts = pagy_array(PostQuery.new.all, items: 10)
```

For Rails, [Kaminari](https://github.com/kaminari/kaminari) also paginates
arrays:

```ruby
@posts = Kaminari.paginate_array(PostQuery.new.all)
                 .page(params[:page]).per(10)
```

For plain Ruby, slice it yourself:

```ruby
pages = PostQuery.new.all.each_slice(10).to_a
```

### Serializing entries

Both `Marquery::Model` and `Marquery::Collection` expose `to_h`, returning a
plain Hash of standard plus declared attributes. Pipe it through any JSON
library you like:

```ruby
require "json"
JSON.generate(post.to_h)
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
