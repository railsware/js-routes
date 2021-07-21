require 'uri'
if defined?(::Rails) && defined?(::Sprockets::Railtie)
  require 'js_routes/engine'
end
require 'js_routes/version'
require 'active_support/core_ext/string/indent'

class JsRoutes

  class Configuration
    DEFAULTS = {
      namespace: nil,
      exclude: [],
      include: //,
      file: nil,
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

    attr_accessor(*DEFAULTS.keys)

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
      normalize
      verify
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
      module_type === 'ESM'
    end

    def dts?
      self.module_type === 'DTS'
    end

    def modern?
      esm? || dts?
    end

    def source_file
      File.dirname(__FILE__) + "/" + default_file_name
    end

    def output_file
      webpacker_dir = Rails.root.join('app', 'javascript')
      sprockets_dir = Rails.root.join('app','assets','javascripts')
      file_name = file || default_file_name
      sprockets_file = sprockets_dir.join(file_name)
      webpacker_file = webpacker_dir.join(file_name)
      !Dir.exist?(webpacker_dir) && defined?(::Sprockets) ? sprockets_file : webpacker_file
    end

    protected

    def default_file_name
      dts? ? "routes.d.ts" : "routes.js"
    end

    def normalize
      self.module_type = module_type&.upcase || 'NIL'
    end

    def verify
      if module_type != 'NIL' && namespace
        raise "JsRoutes namespace option can only be used if module_type is nil"
      end
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

    def generate!(file_name=nil, **opts)
      new(file: file_name, **opts).generate!
    end

    def definitions!(file_name = nil, **opts)
      file_name ||= configuration.file&.sub!(%r{\.(j|t)s\Z}, ".d.ts")
      new(file: file_name, module_type: 'DTS', **opts).generate!
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
    content = File.read(@configuration.source_file)

    if !@configuration.dts?
      content = js_variables.inject(content) do |js, (key, value)|
        js.gsub!("RubyVariables.#{key}", value.to_s) ||
        raise("Missing key #{key} in JS template")
      end
    end
    content + routes_export + prevent_types_export
  end

  def generate!
    # Some libraries like Devise did not load their routes yet
    # so we will wait until initialization process finishes
    # https://github.com/railsware/js-routes/issues/7
    Rails.configuration.after_initialize do
      file_path = Rails.root.join(@configuration.output_file)
      source_code = generate

      # We don't need to rewrite file if it already exist and have same content.
      # It helps asset pipeline or webpack understand that file wasn't changed.
      next if File.exist?(file_path) && File.read(file_path) == source_code

      File.open(file_path, 'w') do |f|
        f.write source_code
      end
    end
  end

  protected

  def js_variables
    {
      'GEM_VERSION'         => JsRoutes::VERSION,
      'ROUTES_OBJECT'       => routes_object,
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
    }
  end

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
    return json({}) if @configuration.modern?
    properties = routes_list.map do |comment, name, body|
      "#{comment}#{name}: #{body}".indent(2)
    end
    "{\n" + properties.join(",\n\n") + "}\n"
  end

  def static_exports
    [:configure, :config, :serialize].map do |name|
      [
        "", name,
        @configuration.dts? ?
          "RouterExposedMethods['#{name}']" :
          "__jsr.#{name}"
      ]
    end
  end

  def routes_export
    return "" unless @configuration.modern?
    [*static_exports, *routes_list].map do |comment, name, body|
      "#{comment}export const #{name}#{export_separator}#{body};\n\n"
    end.join
  end

  def prevent_types_export
    return "" unless @configuration.dts?
    <<-JS
// By some reason this line prevents all types in a file
// from being automatically exported
export {};
    JS
  end

  def export_separator
    @configuration.dts? ? ': ' : ' = '
  end

  def routes_list
    named_routes.sort_by(&:first).flat_map do |_, route|
      route_helpers_if_match(route) + mounted_app_routes(route)
    end
  end

  def mounted_app_routes(route)
    rails_engine_app = app_from_route(route)
    if rails_engine_app.respond_to?(:superclass) &&
       rails_engine_app.superclass == Rails::Engine && !route.path.anchored
      rails_engine_app.routes.named_routes.flat_map do |_, engine_route|
        route_helpers_if_match(engine_route, route)
      end
    else
      []
    end
  end

  def app_from_route(route)
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
    FILTERED_DEFAULT_PARTS = [:controller, :action]
    URL_OPTIONS = [:protocol, :domain, :host, :port, :subdomain]
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

    attr_reader :configuration, :route, :parent_route

    def initialize(configuration, route, parent_route = nil)
      @configuration = configuration
      @route = route
      @parent_route = parent_route
    end

    def helpers
      helper_types.map do |absolute|
        [ documentation, helper_name(absolute), body(absolute) ]
      end
    end

    def helper_types
      return [] unless match_configuration?
      @configuration[:url_links] ? [true, false] : [false]
    end

    def body(absolute)
      @configuration.dts? ?
        definition_body : "__jsr.r(#{arguments(absolute).map{|a| json(a)}.join(', ')})"
    end

    def definition_body
      args = required_parts.map{|p| "#{apply_case(p)}: RequiredRouteParameter"}
      args << "options?: #{optional_parts_type} & RouteOptions"
      "(\n#{args.join(",\n").indent(2)}\n) => string"
    end

    def optional_parts_type
      @optional_parts_type ||=
        "{" + optional_parts.map {|p| "#{p}?: OptionalRouteParameter"}.join(', ') + "}"
    end

    protected

    def arguments(absolute)
      absolute ? [*base_arguments, true] : base_arguments
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

    def optional_parts
      route.path.optional_names
    end

    def base_arguments
      @base_arguments ||= [parts_table, serialize(spec, parent_spec)]
    end

    def parts_table
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
      parts_table
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
