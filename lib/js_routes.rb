class JsRoutes

  #
  # API
  #

  def self.generate(options = {})
    self.new(options).generate
  end

  def self.generate!(options = {})
    self.new(options).generate!
  end

  #
  # Implementation
  #

  def initialize(options = {})
    @options = default_options.merge(options)
  end

  def generate
    js = File.read(File.dirname(__FILE__) + "/routes.js")
    js.gsub!("NAMESPACE", @options[:namespace])
    js.gsub!("DEFAULT_FORMAT", @options[:default_format].to_s)
    js.gsub!("PREFIX", @options[:prefix])
    js.gsub!("ROUTES", js_routes)
  end

  def generate!
    File.open(@options[:file], 'w') do |f|
      f.write generate
    end
  end

  protected

  def js_routes
    Rails.application.reload_routes!
    js_routes = Rails.application.routes.named_routes.routes.map do |_, route|
      if any_match?(route, @options[:exclude]) || !any_match?(route, @options[:include])
        nil
      else
        build_js(route)
      end
    end.compact

    "{\n" + js_routes.join(",\n") + "}\n"
  end

  def any_match?(route, matchers)
    matchers = Array(matchers)
    matchers.any? {|regex| route.name =~ regex}
  end

  def build_js(route)
    params = build_params route
    _ = <<-JS.strip!
  // #{route.name} => #{route.path}
  #{route.name}_path: function(#{params.<<("options").join(", ")}) {
  return Utils.build_path(#{params.size}, #{path_parts(route).inspect}, arguments)
  }
  JS
  end


  def build_params route
    route.conditions[:path_info].named_captures.to_a.sort do |cap1, cap2|
      # Hash is not ordered in Ruby 1.8.7
      cap1.last.first <=> cap2.last.first
    end.map do |cap|
      name = cap.first
      if !(name.to_s == "format")
        # prepending each parameter name with underscore
        # to prevent conflict with JS reserved words
        "_" + name.to_s.gsub(/^:/, '')
      end
    end.compact
  end


  def path_parts route
    route.path.gsub(/\(\.:format\)$/, "").split(/:[a-z\-_]+/)
  end

  def default_options 
    {
      :namespace => "Routes",
      :default_format => "",
      :exclude => [],
      :include => //,
      :file => default_file,
      :prefix => ""
    }
  end

  def default_file
    if Rails.version >= "3.1"
      "#{Rails.root}/app/assets/javascripts/routes.js"
    else
      "#{Rails.root}/public/javascripts/routes.js"
    end
  end

end
