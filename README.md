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
