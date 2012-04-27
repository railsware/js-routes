class JsRoutes

  #
  # OPTIONS
  #

  DEFAULT_PATH = File.join('app','assets','javascripts','routes.js')

  DEFAULTS = {
    :namespace => "Routes",
    :default_format => "",
    :exclude => [],
    :include => //,
    :file => DEFAULT_PATH,
    :prefix => ""
  }

  # We encode node symbols as integer to reduce the routes.js file size
  NODE_TYPES = {
    :GROUP => 1,
    :CAT => 2,
    :SYMBOL => 3,
    :OR => 4,
    :STAR => 5,
    :LITERAL => 6,
    :SLASH => 7,
    :DOT => 8
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

    def generate!(file_name=nil, opts = {})
      if file_name.is_a?(Hash)
        opts = file_name
        file_name = opts[:file]
      end
      new(opts).generate!(file_name)
    end

    # Under rails 3.1.1 and higher, perform a check to ensure that the
    # full environment will be available during asset compilation.
    # This is required to ensure routes are loaded.
    def assert_usable_configuration!
      unless Rails.application.config.assets.initialize_on_precompile
        raise("Cannot precompile js-routes unless environment is initialized. Please set config.assets.initialize_on_precompile to true.")
      end
      true
    end

    def json(string)
      ActiveSupport::JSON.encode(string)
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
    js.gsub!("NODE_TYPES", json(NODE_TYPES))
    js.gsub!("ROUTES", js_routes)
  end

  def generate!(file_name = nil)
    # Some libraries like Devise do not yet loaded their routes so we will wait
    # until initialization process finish
    # https://github.com/railsware/js-routes/issues/7
    Rails.configuration.after_initialize do
      file_name ||= self.class.options['file']
      File.open(Rails.root.join(file_name || DEFAULT_PATH), 'w') do |f|
        f.write generate
      end
    end
  end

  protected

  def js_routes
    Rails.application.reload_routes!
    #engine_routes = Rails::Engine::Railties.engines.map {|e| e.routes.named_routes.routes}.inject({}) {|acc, h| acc.merge(h)}
    js_routes = Rails.application.routes.named_routes.routes.map do |_, route|
      if any_match?(route, @options[:exclude]) || !any_match?(route, @options[:include])
        nil
      elsif route.app.respond_to? :routes
        # route is an engine, lets open it
        route.app.routes.named_routes.routes.map do |_, engine_route|
          if any_match?(engine_route, @options[:exclude]) || !any_match?(engine_route, @options[:include])
            nil
          else
            build_js(engine_route, "#{route.name}_", route.path.spec)
          end
        end
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

  def build_js(route, name_prefix='', path_prefix='')
    _ = <<-JS.strip!
  // #{name_prefix}#{route.name} => #{path_prefix}#{route.path.spec}
  #{name_prefix}#{route.name}_path: function(#{build_params(route)}) {
  return "#{path_prefix}" + Utils.build_path(#{json(route.required_parts)}, #{json(serialize(route.path.spec))}, arguments);
  }
  JS
  end

  def json(string)
    self.class.json(string)
  end

  def build_params route
    params = route.required_parts.map do |name|
      # prepending each parameter name with underscore
      # to prevent conflict with JS reserved words
      "_" + name.to_s
    end << "options"
    params.join(", ")
  end

  # This function serializes Journey route into JSON structure
  # We do not use Hash for human readable serialization
  # And preffer Array serialization because it is shorter.
  # Routes.js file will be smaller.
  def serialize(spec)
    return nil unless spec
    return spec.tr(':', '') if spec.is_a?(String)
    [
      NODE_TYPES[spec.type],
      serialize(spec.left),
      spec.respond_to?(:right) && serialize(spec.right)
    ]
  end
end
