require 'uri'
require 'js_routes/engine' if defined?(Rails)
require 'js_routes/version'

class JsRoutes

  #
  # OPTIONS
  #

  DEFAULT_PATH = File.join('app','assets','javascripts','routes.js')

  DEFAULTS = {
    namespace: "Routes",
    exclude: [],
    include: //,
    file: DEFAULT_PATH,
    prefix: nil,
    url_links: false,
    camel_case: false,
    default_url_options: {},
    compact: false,
    serializer: nil,
    special_options_key: "_options",
  }

  NODE_TYPES = {
    GROUP: 1,
    CAT: 2,
    SYMBOL: 3,
    OR: 4,
    STAR: 5,
    LITERAL: 6,
    SLASH: 7,
    DOT: 8
  }

  LAST_OPTIONS_KEY = "options".freeze
  FILTERED_DEFAULT_PARTS = [:controller, :action, :subdomain]
  URL_OPTIONS = [:protocol, :domain, :host, :port, :subdomain]

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
      if 3 == Rails::VERSION::MAJOR && !Rails.application.config.assets.initialize_on_precompile
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
    # Ensure routes are loaded. If they're not, load them.
    if named_routes.to_a.empty? && application.respond_to?(:reload_routes!)
      application.reload_routes!
    end

    {
      "GEM_VERSION"         => JsRoutes::VERSION,
      "APP_CLASS"           => application.class.to_s,
      "NAMESPACE"           => @options[:namespace],
      "RAILS_VERSION"       => Rails::VERSION::STRING,
      "DEFAULT_URL_OPTIONS" => json(@options[:default_url_options].merge(deprecate_url_options)),
      "PREFIX"              => @options[:prefix] || Rails.application.config.relative_url_root || "",
      "NODE_TYPES"          => json(NODE_TYPES),
      "SERIALIZER"          => @options[:serializer] || json(nil),
      "ROUTES"              => js_routes,
      "SPECIAL_OPTIONS_KEY" => @options[:special_options_key].to_s
    }.inject(File.read(File.dirname(__FILE__) + "/routes.js")) do |js, (key, value)|
      js.gsub!(key, value)
    end
  end

  def deprecate_url_options
    result = {}
    if @options.key?(:default_format)
      warn("default_format option is deprecated. Use default_url_options = { format: <format> } instead")
      result.merge!(  format: @options[:default_format]  )
    end
    if @options[:url_links].is_a?(String)
      ActiveSupport::Deprecation.warn('js-routes url_links config value must be a boolean. Use default_url_options for specifying a default host.')

      raise "invalid URL format in url_links (ex: http[s]://example.com)" if @options[:url_links].match(URI::Parser.new.make_regexp(%w(http https))).nil?
      uri = URI.parse(@options[:url_links])
      default_port = uri.scheme == "https" ? 443 : 80
      port = uri.port == default_port ? nil : uri.port
      result.merge!(
        host: uri.host,
        port: port,
        protocol: uri.scheme,
      )
    end
    result
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

  def application
    @options[:application] || Rails.application
  end

  def named_routes
    application.routes.named_routes.to_a
  end

  def js_routes
    js_routes = named_routes.sort_by(&:first).flat_map do |_, route|
      [build_route_if_match(route)] + mounted_app_routes(route)
    end.compact
    "{\n" + js_routes.join(",\n") + "}\n"
  end

  def mounted_app_routes(route)
    rails_engine_app = get_app_from_route(route)
    if rails_engine_app.respond_to?(:superclass) && rails_engine_app.superclass == Rails::Engine && !route.path.anchored
      rails_engine_app.routes.named_routes.map do |_, engine_route|
        build_route_if_match(engine_route, route)
      end
    else
      []
    end
  end

  def get_app_from_route(route)
    # rails engine in Rails 4.2 use additional ActionDispatch::Routing::Mapper::Constraints, which contain app
    if route.app.respond_to?(:app) && route.app.respond_to?(:constraints)
      route.app.app
    else
      route.app
    end
  end

  def build_route_if_match(route, parent_route=nil)
    if any_match?(route, parent_route, @options[:exclude]) || !any_match?(route, parent_route, @options[:include])
      nil
    else
      build_js(route, parent_route)
    end
  end

  def any_match?(route, parent_route, matchers)
    full_route = [parent_route.try(:name), route.name].compact.join('_')

    matchers = Array(matchers)
    matchers.any? {|regex| full_route =~ regex}
  end

  def build_js(route, parent_route)
    name = [parent_route.try(:name), route.name].compact
    route_name = generate_route_name(name, (:path unless @options[:compact]))
    parent_spec = parent_route.try(:path).try(:spec)
    route_arguments = route_js_arguments(route, parent_spec)
    url_link = generate_url_link(name, route_name, route_arguments, route)
    _ = <<-JS.strip!
  // #{name.join('.')} => #{parent_spec}#{route.path.spec}
  // function(#{build_params(route.required_parts)})
  #{route_name}: Utils.route(#{route_arguments})#{",\n" + url_link if url_link.length > 0}
  JS
  end

  def route_js_arguments(route, parent_spec)
    required_parts = route.required_parts
    parts_table = route.parts.each_with_object({}) do |part, hash|
      hash[part] = required_parts.include?(part)
    end
    default_options = route.defaults.select do |part, _|
      FILTERED_DEFAULT_PARTS.exclude?(part) && URL_OPTIONS.include?(part) || parts_table[part]
    end
    [
      # JS objects don't preserve the order of properties which is crucial,
      # so array is a better choice.
      parts_table.to_a,
      default_options,
      serialize(route.path.spec, parent_spec)
    ].map do |argument|
      json(argument)
    end.join(", ")
  end

  def generate_url_link(name, route_name, route_arguments, route)
    return "" unless @options[:url_links]
    <<-JS.strip!
    #{generate_route_name(name, :url)}: Utils.route(#{route_arguments}, true)
    JS
  end

  def generate_route_name(name, suffix)
    route_name = name.join('_')
    route_name << "_#{ suffix }" if suffix
    @options[:camel_case] ? route_name.camelize(:lower) : route_name
  end

  def json(string)
    self.class.json(string)
  end

  def build_params(required_parts)
    params = required_parts + [LAST_OPTIONS_KEY]
    params.join(", ")
  end

  # This function serializes Journey route into JSON structure
  # We do not use Hash for human readable serialization
  # And preffer Array serialization because it is shorter.
  # Routes.js file will be smaller.
  def serialize(spec, parent_spec=nil)
    return nil unless spec
    return spec.tr(':', '') if spec.is_a?(String)
    result = serialize_spec(spec, parent_spec)
    if parent_spec && result[1].is_a?(String)
      result = [
        # We encode node symbols as integer
        # to reduce the routes.js file size
        NODE_TYPES[:CAT],
        serialize_spec(parent_spec),
        result
      ]
    end
    result
  end

  def serialize_spec(spec, parent_spec=nil)
    [
      NODE_TYPES[spec.type],
      serialize(spec.left, parent_spec),
      spec.respond_to?(:right) && serialize(spec.right)
    ]
  end
end

