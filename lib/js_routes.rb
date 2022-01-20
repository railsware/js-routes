require 'uri'
require "pathname"

if defined?(::Rails) && defined?(::Sprockets::Railtie)
  require 'js_routes/engine'
end
require 'js_routes/version'
require "js_routes/route"
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
      normalize_and_verify
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

    def require_esm
      raise "ESM module type is required" unless modern?
    end

    def source_file
      File.dirname(__FILE__) + "/" + default_file_name
    end

    def output_file
      webpacker_dir = pathname('app', 'javascript')
      sprockets_dir = pathname('app','assets','javascripts')
      file_name = file || default_file_name
      sprockets_file = sprockets_dir.join(file_name)
      webpacker_file = webpacker_dir.join(file_name)
      !Dir.exist?(webpacker_dir) && defined?(::Sprockets) ? sprockets_file : webpacker_file
    end

    def normalize_and_verify
      normalize
      verify
    end

    protected

    def pathname(*parts)
      Pathname.new(File.join(*parts))
    end

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
      configuration.normalize_and_verify
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def generate(**opts)
      new(opts).generate
    end

    def generate!(file_name=nil, **opts)
      new(file: file_name, **opts).generate!
    end

    def definitions(**opts)
      generate(module_type: 'DTS', **opts)
    end

    def definitions!(file_name = nil, **opts)
      file_name ||= configuration.file&.sub(%r{(\.d)?\.(j|t)s\Z}, ".d.ts")
      generate!(file_name, module_type: 'DTS', **opts)
    end

    def json(string)
      ActiveSupport::JSON.encode(string)
    end
  end

  attr_reader :configuration
  #
  # Implementation
  #

  def initialize(options = {})
    @configuration = self.class.configuration.merge(options)
  end

  def generate
    # Ensure routes are loaded. If they're not, load them.
    if named_routes.empty? && application.respond_to?(:reload_routes!)
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
    app = route.app
    # rails engine in Rails 4.2 use additional
    # ActionDispatch::Routing::Mapper::Constraints, which contain app
    if app.respond_to?(:app) && app.respond_to?(:constraints)
      app.app
    else
      app
    end
  end

  def route_helpers_if_match(route, parent_route = nil)
    Route.new(@configuration, route, parent_route).helpers
  end

  module Generators
  end
end

require "js_routes/middleware"
require "js_routes/generators/webpacker"
require "js_routes/generators/middleware"
