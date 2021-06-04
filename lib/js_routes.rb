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
    namespace: nil,
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
    module_type: 'ESM',
    documentation: true,
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

    def esm?
      self.module_type === 'ESM'
    end
  end

  #
  # API
  #

  class << self
    def setup(&block)
      configuration.tap(&block) if block
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
      'ROUTES_OBJECT'              => routes_object,
      'RAILS_VERSION'       => ActionPack.version,
      'DEPRECATED_GLOBBING_BEHAVIOR' => ActionPack::VERSION::MAJOR == 4 && ActionPack::VERSION::MINOR == 0,

      'APP_CLASS'           => application.class.to_s,
      'NAMESPACE'           => json(@configuration.namespace),
      'DEFAULT_URL_OPTIONS' => json(@configuration.default_url_options),
      'PREFIX'              => json(@configuration.prefix),
      'SPECIAL_OPTIONS_KEY' => json(@configuration.special_options_key),
      'SERIALIZER'          => @configuration.serializer || json(nil),
      'MODULE_TYPE'         => json(@configuration.module_type),
      'WRAPPER'             => @configuration.esm? ? 'const __jsr = ' : '',
    }.inject(File.read(File.dirname(__FILE__) + "/routes.js")) do |js, (key, value)|
      js.gsub!("RubyVariables.#{key}", value.to_s) ||
        raise("Missing key #{key} in JS template")
    end + routes_export
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

  def json(string)
    self.class.json(string)
  end

  def named_routes
    application.routes.named_routes.to_a
  end

  def routes_object
    return json({}) if @configuration.esm?
    properties = routes_list.map do |comment, name, body|
      "#{comment}#{name}: #{body}".indent(2)
    end
    "{\n" + properties.join(",\n\n") + "}\n"
  end

  STATIC_EXPORTS = [:configure, :config, :serialize].map do |name|
    ["", name, "__jsr.#{name}"]
  end

  def routes_export
    return "" unless @configuration.esm?
    [*STATIC_EXPORTS, *routes_list].map do |comment, name, body|
      "#{comment}export const #{name} = #{body};"
    end.join("\n\n")
  end

  def routes_list
    named_routes.sort_by(&:first).flat_map do |_, route|
      route_helpers_if_match(route) + mounted_app_routes(route)
    end.compact
  end

  def mounted_app_routes(route)
    rails_engine_app = get_app_from_route(route)
    if rails_engine_app.respond_to?(:superclass) &&
       rails_engine_app.superclass == Rails::Engine && !route.path.anchored
      rails_engine_app.routes.named_routes.flat_map do |_, engine_route|
        route_helpers_if_match(engine_route, route)
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

  def route_helpers_if_match(route, parent_route = nil)
    JsRoute.new(@configuration, route, parent_route).helpers
  end

  class JsRoute #:nodoc:
    attr_reader :configuration, :route, :parent_route

    def initialize(configuration, route, parent_route = nil)
      @configuration = configuration
      @route = route
      @parent_route = parent_route
    end

    def helpers
      unless match_configuration?
        []
      else
        [false, true].map do |absolute|
          absolute && !@configuration[:url_links] ?
            nil : [ documentation, helper_name(absolute), body(absolute) ]
        end
      end
    end

    def body(absolute)
      "__jsr.r(#{arguments(absolute).join(', ')})"
    end

    def arguments(absolute)
      absolute ? base_arguments + [json(true)] : base_arguments
    end

    def match_configuration?
      !match?(@configuration[:exclude]) && match?(@configuration[:include])
    end

    def base_name
      @base_name ||= parent_route ?
        [parent_route.name, route.name].join('_') : route.name
    end

    def parent_spec
      parent_route&.path&.spec
    end

    def spec
      route.path.spec
    end

    def json(value)
      JsRoutes.json(value)
    end

    def helper_name(absolute)
      suffix = absolute ? :url : @configuration[:compact] ? nil : :path
      apply_case(base_name, suffix)
    end

    def documentation
      return nil unless @configuration[:documentation]
      <<-JS
/**
 * Generates rails route to
 * #{parent_spec}#{spec}#{documentation_params}
 * @param {object | undefined} options
 * @returns {string} route path
 */
JS
    end

    def required_parts
      route.required_parts
    end

    protected

    def base_arguments
      return @base_arguments if defined?(@base_arguments)
      parts_table = {}
      route.parts.each do |part, hash|
        parts_table[part] ||= {}
        if required_parts.include?(part)
          # Using shortened keys to reduce js file size
          parts_table[part][:r] = true
        end
      end
      route.defaults.each do |part, value|
        if FILTERED_DEFAULT_PARTS.exclude?(part) &&
          URL_OPTIONS.include?(part) || parts_table[part]
          parts_table[part] ||= {}
          # Using shortened keys to reduce js file size
          parts_table[part][:d] = value
        end
      end
      @base_arguments = [
        parts_table, serialize(spec, parent_spec)
      ].map do |argument|
        json(argument)
      end
    end

    def documentation_params
      required_parts.map do |param|
        "\n * @param {any} #{apply_case(param)}"
      end.join
    end

    def match?(matchers)
      Array(matchers).any? { |regex| base_name =~ regex }
    end

    def apply_case(*values)
      value = values.compact.map(&:to_s).join('_')
      @configuration[:camel_case] ? value.camelize(:lower) : value
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
      if parent_spec && result[1].is_a?(String) && parent_spec.type != :SLASH
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
        spec.respond_to?(:right) ? serialize(spec.right) : nil
      ].compact
    end
  end
end
