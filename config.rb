###
# Page options, layouts, aliases and proxies
###

# Choose stylesheet theme: glide, hamilton, epsilon
config[:theme] = 'epsilon'

set :layouts_dir, 'themes/' + config[:theme] + '/layouts'
set :css_dir, 'themes/' + config[:theme] + '/stylesheets'
set :js_dir, 'themes/' + config[:theme] + '/javascripts'

# Per-page layout changes:
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# Take steps to ignore the themes we aren't using, including:
# 1. Ignore the unchosen themes so they aren't built.
# 2. Ignore ALL theme layouts from the sitemap (prevents SystemStackError). See also: https://github.com/middleman/middleman/issues/1243
ignore(/themes\/(?!#{config[:theme]}).*/)
config.ignored_sitemap_matchers[:layout] = proc { |file|
  file = file.relative_path.to_s
  file.start_with?(File.join(config.source, 'layout.')) || file.start_with?(File.join(config.source, 'layouts/')) || !!(file =~ /themes\/.*\/layouts\//)
}

require "lib/custom_helpers"
helpers CustomHelpers

activate :navtree do |config|
  config[:ignore_files] = ["404.html.md", "sitemap.xml.erb", "robots.txt"]
  config[:ignore_dir] = ["themes", "updates"]
  config[:promote_files] = ["index.html.haml"]
end

activate :syntax

# default en locale
activate :i18n

set :markdown_engine, :kramdown
set :markdown, :fenced_code_blocks => true, :smartypants => true

activate :blog do |blog|
  blog[:prefix] = "updates"
  blog[:permalink] = "{year}-{month}-{day}-{title}.html"
  blog[:publish_future_dated] = true
end

# Build-specific configuration
configure :build do
  activate :minify_css
  activate :minify_javascript
  # Append a hash to asset urls (make sure to use the url helpers)
  activate :asset_hash
end

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end
