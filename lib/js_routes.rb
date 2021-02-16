require 'uri'
if defined?(::Rails) && defined?(::Sprockets::Railtie)
  require 'js_routes/engine'
end
require 'js_routes/version'
require 'active_support/core_ext/string/indent'

class JsRoutes

  #
  # OPTIONS
  #

  DEFAULTS = {
    namespace: -> { defined?(Webpacker) ? nil : "Routes" },
    exclude: [],
    include: //,
    file: -> do
      webpacker_dir = Rails.root.join('app', 'javascript')
      sprockets_dir = Rails.root.join('app','assets','javascripts')
      sprockets_file = sprockets_dir.join('routes.js')
      webpacker_file = webpacker_dir.join('routes.js')
      !Dir.exist?(webpacker_dir) && defined?(::Sprockets) ? sprockets_file : webpacker_file
    end,
    prefix: -> { Rails.application.config.relative_url_root || "" },
    url_links: false,
    camel_case: false,
    default_url_options: {},
    compact: false,
    serializer: nil,
    special_options_key: "_options",
    application: -> { Rails.application },
    module_type: 'UMD',
  } #:nodoc:

  NODE_TYPES = {
    GROUP: 1,
    CAT: 2,
    SYMBOL: 3,
    OR: 4,
    STAR: 5,
    LITERAL: 6,
    SLASH: 7,
    DOT: 8
  } #:nodoc:

  LAST_OPTIONS_KEY = "options".freeze #:nodoc:
  FILTERED_DEFAULT_PARTS = [:controller, :action] #:nodoc:
  URL_OPTIONS = [:protocol, :domain, :host, :port, :subdomain] #:nodoc:

  class Configuration < Struct.new(*DEFAULTS.keys)
    def initialize(attributes = nil)
      assign(DEFAULTS)
      return unless attributes
      assign(attributes)
    end

    def assign(attributes)
      attributes.each do |attribute, value|
        value = value.call if value.is_a?(Proc)
        send(:"#{attribute}=", value)
      end
      self
    end

    def [](attribute)
      send(attribute)
    end

    def merge(attributes)
      clone.assign(attributes)
    end

    def to_hash
      Hash[*members.zip(values).flatten(1)].symbolize_keys
    end
  end

  #
  # API
  #

  class << self
    def setup(&block)
      configuration.tap(&block) if block
    end

    def options
      ActiveSupport::Deprecation.warn('JsRoutes.options method is deprecated use JsRoutes.configuration instead')
      configuration
    end

    def configuration
      @configuration ||= Configuration.new
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

    def json(string)
      ActiveSupport::JSON.encode(string)
    end
  end

  #
  # Implementation
  #

  def initialize(options = {})
    @configuration = self.class.configuration.merge(options)
  end

  def generate
    # Ensure routes are loaded. If they're not, load them.
    if named_routes.to_a.empty? && application.respond_to?(:reload_routes!)
      application.reload_routes!
    end

    {
      'GEM_VERSION'         => JsRoutes::VERSION,
      'ROUTES'              => routes_object,
      'RAILS_VERSION'       => ActionPack.version,
      'DEPRECATED_GLOBBING_BEHAVIOR' => ActionPack::VERSION::MAJOR == 4 && ActionPack::VERSION::MINOR == 0,

      'APP_CLASS'           => application.class.to_s,
      'NAMESPACE'           => json(@configuration.namespace),
      'DEFAULT_URL_OPTIONS' => json(@configuration.default_url_options),
      'PREFIX'              => json(@configuration.prefix),
      'SPECIAL_OPTIONS_KEY' => json(@configuration.special_options_key),
      'SERIALIZER'          => @configuration.serializer || json(nil),
      'MODULE_TYPE'         => json(@configuration.module_type),
    }.inject(File.read(File.dirname(__FILE__) + "/routes.js")) do |js, (key, value)|
      js.gsub!("RubyVariables.#{key}", value.to_s) ||
        raise("Missing key #{key} in JS template")
    end
  end

  def generate!(file_name = nil)
    # Some libraries like Devise do not yet loaded their routes so we will wait
    # until initialization process finish
    # https://github.com/railsware/js-routes/issues/7
    Rails.configuration.after_initialize do
      file_name ||= self.class.configuration['file']
      file_path = Rails.root.join(file_name)
      js_content = generate

      # We don't need to rewrite file if it already exist and have same content.
      # It helps asset pipeline or webpack understand that file wasn't changed.
      next if File.exist?(file_path) && File.read(file_path) == js_content

      File.open(file_path, 'w') do |f|
        f.write js_content
      end
    end
  end

  protected

  def application
    @configuration.application
  end

  def named_routes
    application.routes.named_routes.to_a
  end

  def routes_object
    result = named_routes.sort_by(&:first).flat_map do |_, route|
      build_routes_if_match(route) + mounted_app_routes(route)
    end.compact
    properties = result.map do |comment, name, body|
      "#{comment}\n#{name}: #{body}".indent(2)
    end
    "{\n" + properties.join(",\n\n") + "}\n"
  end

  def mounted_app_routes(route)
    rails_engine_app = get_app_from_route(route)
    if rails_engine_app.respond_to?(:superclass) &&
       rails_engine_app.superclass == Rails::Engine && !route.path.anchored
      rails_engine_app.routes.named_routes.flat_map do |_, engine_route|
        build_routes_if_match(engine_route, route)
      end
    else
      []
    end
  end

  def get_app_from_route(route)
    # rails engine in Rails 4.2 use additional
    # ActionDispatch::Routing::Mapper::Constraints, which contain app
    if route.app.respond_to?(:app) && route.app.respond_to?(:constraints)
      route.app.app
    else
      route.app
    end
  end

  def build_routes_if_match(route, parent_route = nil)
    if any_match?(route, parent_route, @configuration[:exclude]) ||
       !any_match?(route, parent_route, @configuration[:include])
      []
    else
      name = [parent_route.try(:name), route.name].compact
      parent_spec = parent_route.try(:path).try(:spec)
      route_arguments = route_js_arguments(route, parent_spec)
      return [false, true].map do |absolute|
        route_js(name, parent_spec, route, route_arguments, absolute)
      end
    end
  end

  def any_match?(route, parent_route, matchers)
    full_route = [parent_route.try(:name), route.name].compact.join('_')

    matchers = Array(matchers)
    matchers.any? { |regex| full_route =~ regex }
  end

  def route_js(name_parts, parent_spec, route, route_arguments, absolute)
    if absolute
      return nil unless @configuration[:url_links]
      route_arguments = route_arguments + [json(true)]
    end
    name_suffix = absolute ? :url : @configuration[:compact] ? nil : :path
    name = generate_route_name(name_parts, name_suffix)
    body = "Utils.route(#{route_arguments.join(', ')})"
    comment = <<-JS.rstrip!
// #{name_parts.join('.')} => #{parent_spec}#{route.path.spec}
// function(#{build_params(route.required_parts)})
JS

    [ comment, name, body ]
  end

  def route_js_arguments(route, parent_spec)
    required_parts = route.required_parts
    parts_table = {}
    route.parts.each do |part, hash|
      parts_table[part] = {required: required_parts.include?(part)}
    end
    route.defaults.each do |part, value|
      if FILTERED_DEFAULT_PARTS.exclude?(part) &&
        URL_OPTIONS.include?(part) || parts_table[part]
        parts_table[part] ||= {}
        parts_table[part][:default] = value
      end
    end
    [
      parts_table.to_a.map do |key, config|
        # Optmizing JS file size by using
        # an Array with optional elements instead of Hash
        # [key: string, required?: boolean, default?: any]
        if config.has_key?(:default) && !config[:default].nil?
          [key, config[:required], config[:default]]
        else
          config[:required] ? [key, config[:required]] : [key]
        end
      end,
      # default_options,
      serialize(route.path.spec, parent_spec)
    ].map do |argument|
      json(argument)
    end
  end

  def generate_route_name(*parts)
    route_name = parts.compact.join('_')
    @configuration[:camel_case] ? route_name.camelize(:lower) : route_name
  end

  def json(string)
    self.class.json(string)
  end

  def build_params(required_parts)
    params = required_parts + [LAST_OPTIONS_KEY]
    params.join(', ')
  end

  # This function serializes Journey route into JSON structure
  # We do not use Hash for human readable serialization
  # And preffer Array serialization because it is shorter.
  # Routes.js file will be smaller.
  def serialize(spec, parent_spec=nil)
    return nil unless spec
    # Rails 4 globbing requires * removal
    return spec.tr(':*', '') if spec.is_a?(String)

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

  def serialize_spec(spec, parent_spec = nil)
    [
      NODE_TYPES[spec.type],
      serialize(spec.left, parent_spec),
      spec.respond_to?(:right) && serialize(spec.right)
    ]
  end
end
