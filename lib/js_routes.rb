class JsRoutes

  #
  # OPTIONS
  #

  DEFAULT_PATH = if Rails.version >= "3.1"
                   File.join('app','assets','javascripts','routes.js')
                 else
                   File.join('public','javascripts','routes.js')
                 end

  DEFAULTS = {
    :namespace => "Routes",
    :default_format => "",
    :exclude => [],
    :include => //,
    :file => DEFAULT_PATH,
    :prefix => ""
  }

  class Options < Struct.new(*DEFAULTS.keys)
    def to_hash
      Hash[*members.zip(values).flatten(1)].symbolize_keys
    end
  end

  #
  # API
  #

  class << self
    def setup(&block)
      options.tap(&block) if block
    end

    def options
      @options ||= Options.new.tap do |opts|
        DEFAULTS.each_pair {|k,v| opts[k] = v}
      end
    end

    def generate(opts = {})
      new(opts).generate
    end

    def generate!(opts = {})
      new(opts).generate!
    end

    # Under rails 3.1.1 and higher, perform a check to ensure that the
    # full environment will be available during asset compilation.
    # This is required to ensure routes are loaded.
    def assert_usable_configuration!
      if Rails.version > "3.1.0" && !Rails.application.config.assets.initialize_on_precompile 
        raise("Cannot precompile js-routes unless environment is initialized. Please set config.assets.initialize_on_precompile to true.")
      end
      true
    end
  end

  #
  # Implementation
  #

  def initialize(options = {})
    @options = self.class.options.to_hash.merge(options)
  end

  def generate
    js = File.read(File.dirname(__FILE__) + "/routes.js")
    js.gsub!("NAMESPACE", @options[:namespace])
    js.gsub!("DEFAULT_FORMAT", @options[:default_format].to_s)
    js.gsub!("PREFIX", @options[:prefix])
    js.gsub!("ROUTES", js_routes)
  end

  def generate!
    # Some libraries like Devise do not yet loaded their routes so we will wait
    # until initialization process finish
    # https://github.com/railsware/js-routes/issues/7
    Rails.configuration.after_initialize do
      File.open(Rails.root.join(@options[:file]), 'w') do |f|
        f.write generate
      end
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
  #{route.name}_path: function(#{(params + ["options"]).join(", ")}) {
  return Utils.build_path(#{params.size}, #{path_parts(route).inspect}, #{optional_params(route).inspect}, arguments)
  }
  JS
  end

  # TODO: might be possible to simplify this to use route.path
  # instead of all this path_info.source madness
  def optional_params(route)
    if RUBY_VERSION >= '1.9.2'
      optional_named_captures_regexp = /\?\:.+?\(\?\<(.+?)\>/
      path_info = route.conditions[:path_info]
      path_info.source.scan(optional_named_captures_regexp).flatten
    else
      re = Regexp.escape("([^/.?]+)")
      optional_named_captures_regexp = /#{re}|\(\?\:.+?\)\?/
      path_info = route.conditions[:path_info]
      captures = path_info.source.scan(optional_named_captures_regexp).flatten
      named_captures = path_info.named_captures.to_a.sort_by {|cap|cap.last.first} 
      captures.zip(named_captures).map do |type, (name, pos)|
        name unless type == '([^/.?]+)'
      end.compact
    end
  end

  def build_params route
    optional_named_captures = optional_params(route)
    route.conditions[:path_info].named_captures.to_a.sort_by do |cap1|
      # Hash is not ordered in Ruby 1.8.7
      cap1.last.first
    end.map do |cap|
      name = cap.first
        if !(optional_named_captures.include?(name.to_s))
        # prepending each parameter name with underscore
        # to prevent conflict with JS reserved words
        "_" + name.to_s
      end
    end.compact
  end


  def path_parts route
    route.path.gsub(/\(\.:format\)$/, "").split(/:[a-z\-_]+/)
  end
end
