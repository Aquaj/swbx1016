#Livereload
activate :livereload

require 'dotenv'
Dotenv.load

### 
# Compass
###

# Susy grids in Compass
# First: gem install compass-susy-plugin
# require 'susy'

# Change Compass configuration
compass_config do |config|
  config.output_style = :compact
  config.line_comments = false
end

set :fonts_dir, "fonts"
activate :asset_hash
activate :relative_assets

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
# 
# With no layout
# page "/path/to/file.html", :layout => false
# 
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
# 
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy (fake) files
# page "/this-page-has-no-template.html", :proxy => "/template-file.html" do
#   @which_fake_page = "Rendering a fake page with a variable"
# end

###
# Helpers
###

helpers do
  OPTIONS = [:colors, :credits, :exporting, :labels, :legend, :loading, :navigation, :pane, :plot_options, :series, :subtitle, :title, :tooltip, :x_axis, :y_axis].each_with_object({}) do |name, hash|
    hash[name] = name.to_s.tr('_', '-') # camelize(:lower)
    hash
  end.freeze

  TYPES = [:line, :spline, :area, :area_spline, :column, :bar, :pie, :scatter, :area_range, :area_spline_range, :column_range, :waterfall].each_with_object({}) do |name, hash|
    hash[name] = name.to_s.delete('_')
    hash
  end.freeze

  def lightness(color)
    r = color[1..2].to_i(16)
    g = color[3..4].to_i(16)
    b = color[5..6].to_i(16)
    0.299 * r + 0.587 * g + 0.114 * b
  end

  def contrasted_color(color)
    if lightness(color) > 160
      '#000000'
    else
      '#FFFFFF'
    end
  end

  def jsonize_keys(hash)
    hash.deep_transform_keys do |key|
      key.to_s.camelize(:lower)
    end
  end

  def ligthen(color, rate)
    r = color[1..2].to_i(16)
    g = color[3..4].to_i(16)
    b = color[5..6].to_i(16)
    r *= (1 + rate)
    g *= (1 + rate)
    b *= (1 + rate)
    r = 255 if r > 255
    g = 255 if g > 255
    b = 255 if b > 255
    '#' + r.to_i.to_s(16).rjust(2, '0') + g.to_i.to_s(16).rjust(2, '0') + b.to_i.to_s(16).rjust(2, '0')
  end

  for type, absolute_type in TYPES
    code = "def #{type}_highcharts(series, options = {}, html_options = {})\n"
    code << "  options[:chart] ||= {}\n"
    code << "  options[:chart][:type] = '#{absolute_type}'\n"
    code << "  options[:chart][:style] ||= {}\n"
    code << "  options[:chart][:style][:font_family] ||= 'OpenSans'\n"
    code << "  options[:chart][:style][:font_size]   ||= '0.8rem'\n"
    code << "  options[:colors] ||= ['#2f7ed8', '#0d233a', '#8bbc21', '#910000', '#1aadce', '#492970',
               '#f28f43', '#77a1e5', '#c42525', '#a6c96a']\n"
    code << "  if options[:title].is_a?(String)\n"
    code << "    options[:title] = {text: options[:title].dup}\n"
    code << "  end\n"
    code << "  if options[:subtitle].is_a?(String)\n"
    code << "    options[:subtitle] = {text: options[:subtitle].dup}\n"
    code << "  end\n"
    code << "  series = [series] unless series.is_a?(Array)\n"
    code << "  options[:series] = series\n"
    for name, absolute_name in OPTIONS
      if [:legend, :credits].include?(name)
        code << "  if options.has_key?(:#{name})\n"
        code << "    options[:#{name}] = {enabled: true} if options[:#{name}].is_a?(TrueClass)\n"
        code << "  end\n"
      end
      code << "  options[:#{name}][:enabled] = true if options[:#{name}].is_a?(Hash) and !options[:#{name}].has_key?(:enabled)\n"
    end
    code << "  html_options[:data] ||= {}\n"
    code << "  html_options[:data][:highcharts] = jsonize_keys(options).to_json\n"
    code << "  return content_tag(:div, nil, html_options)\n"
    code << "end\n"
    # code.split("\n").each_with_index{|x, i| puts((i+1).to_s.rjust(4)+": "+x)}
    eval(code)
  end

  def normalize_serie(values, x_values, default = 0.0)
    x_values.map do |x|
      (values[x] || default).to_s.to_f
    end
  end

  # Permit to produce pie or gauge
  # Values are represented relatively to all
  #   engine:     Engine for rendering. c3 by default.
  def distribution_chart(_options = {})
    raise NotImplemented
  end

  # Permits to draw a nonlinear chart (line, spline)
  # Values are represented with given abscissa for each value
  #   :abscissa
  #   :ordinates
  #   engine:     Engine for rendering. c3 by default.
  def category_chart(options = {})
    html_options = options.slice!(:series, :abscissa, :ordinates, :engine)
    options[:type] = :nonlinear
    # TODO: Check options validity
    html_options[:class] ||= 'chart'
    html_options.deep_merge!(data: { chart: options.to_json })
    content_tag(:div, nil, html_options)
  end

  # Permits to draw a linear chart (line, spline, bar)
  # Values are represented with regular interval
  #   series:    (Array of) Hash for series
  #     name:       ID
  #     values:     Array of numeric values
  #     label:      Label for the legend
  #     ordinate:   Name of the used ordinate
  #     type:       One of: line, spline, bar
  #     area:       Boolean
  #     style:      Styles
  #   abscissa:   X axis details
  #     label:      Label for the X axis
  #     values:     Array of labels used for indexes
  #   ordinates: (Array of) Hash for Y axes
  #     name:       ID
  #     label:      Name of the Y axis
  #   engine:     Engine for rendering. c3 by default.
  def cartesian_chart(options = {})
    html_options = options.slice!(:series, :abscissa, :ordinates, :engine)
    options[:type] = :time
    # TODO: Check options validity
    options[:series] = [options[:series]] unless options[:series].is_a?(Array)
    options[:series].each do |serie|
      serie[:values].each do |coordinates|
        coordinates[0] = coordinates[0].utc.l(format: '%Y-%m-%dT%H:%M:%S')
      end
    end
    html_options[:class] ||= 'chart'
    html_options.deep_merge!(data: { chart: options.to_json })
    content_tag(:div, nil, html_options)
  end

  # Permit to produce pie or gauge
  # Values are represented relatively to all
  #   engine:     Engine for rendering. c3 by default.
  def tree_distribution_chart(_options = {})
    raise NotImplemented
  end
end

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

set :css_dir, 'assets/css'
set :js_dir, 'assets/js'
set :images_dir, 'assets/img'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css
  
  # Minify Javascript on build
  activate :minify_javascript
  
  # Create favicon/touch icon set from source/favicon_base.png
  activate :favicon_maker
  
  # Enable cache buster
  # activate :cache_buster
  
  # Use relative URLs
  # activate :relative_assets
  
  # Compress PNGs after build
  # First: gem install middleman-smusher
  # require "middleman-smusher"
  # activate :smusher
  
  # Or use a different image path
  # set :http_path, "/Content/images/"
end
