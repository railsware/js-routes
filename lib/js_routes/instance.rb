# typed: strict
require "js_routes/configuration"
require "js_routes/route"
require "js_routes/types"
require 'fileutils'

module JsRoutes
  class Instance # :nodoc:
    include JsRoutes::Types
    extend T::Sig

    sig { returns(JsRoutes::Configuration) }
    attr_reader :configuration
    #
    # Implementation
    #

    sig { params(options: T.untyped).void }
    def initialize(**options)
      options = T.let(options, Options)
      @configuration = T.let(JsRoutes.configuration.merge(options), JsRoutes::Configuration)
    end

    sig {returns(String)}
    def generate
      # Ensure routes are loaded. If they're not, load them.

      application = T.unsafe(self.application)
      if routes_from(application).empty?
        if application.is_a?(Rails::Application)
          if JsRoutes::Utils.rails_version >= Gem::Version.new("8.0.0")
            T.unsafe(application).reload_routes_unless_loaded
          else
            T.unsafe(application).reload_routes!
          end
        end
      end

      unless @configuration.module_type == "NIL"
        banner + jsr + routes_export
      else
        # Strip the empty IMPORT_ROUTER statement (comment + semicolon) left after substitution
        jsr.sub(/\A(\/\/[^\n]+\n)*;\n/, "")
      end

    end

    sig {returns(String)}
    def package
      raise "Package generation requires module_type: 'PKG'" unless @configuration.pkg?

      jsr
    end

    sig { returns(String) }
    def banner
      banner = @configuration.banner
      banner = banner.call if banner.is_a?(Proc)
      return "" if banner.blank?
      [
        "/**",
        *banner.split("\n").map { |line| " * #{line}" },
        " */",
        "",
      ].join("\n")
    end

    sig { void }
    def generate!
      # Some libraries like Devise did not load their routes yet
      # so we will wait until initialization process finishes
      # https://github.com/railsware/js-routes/issues/7
      T.unsafe(Rails).configuration.after_initialize do
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

    sig { void }
    def package!
      raise "Package generation requires module_type: 'PKG'" unless @configuration.pkg?

      file_path = Rails.root.join(@configuration.output_file)
      source_code = package

      # We don't need to rewrite file if it already exist and have same content.
      # It helps asset pipeline or webpack understand that file wasn't changed.
      return if File.exist?(file_path) && File.read(file_path) == source_code

      File.open(file_path, 'w') do |f|
        f.write source_code
      end
    end

    sig { void }
    def remove!
      path = Rails.root.join(@configuration.output_file)
      FileUtils.rm_rf(path)
      FileUtils.rm_rf(path.sub(%r{\.js\z}, '.d.ts'))
    end

    protected

    ESM_MODULE_MARKER = /export \{\};\n?\z/

    def read_js(path)
      File.read(path).sub(ESM_MODULE_MARKER, "")
    end

    sig { returns(String) }
    def jsr
      return pkg_jsr if @configuration.pkg?

      if @configuration.dts?
        return File.read(@configuration.router_source_file)
      end

      content = read_js(@configuration.source_file)

      js_variables.inject(content) do |js, (key, value)|
        js.gsub!("RubyVariables.#{key}", value.to_s) ||
        raise("Missing key #{key} in JS template")
      end
    end

    sig { returns(String) }
    def pkg_jsr
      read_js(@configuration.router_source_file) + "export default Router;\n"
    end

    sig { returns(T::Hash[String, String]) }
    def js_variables
      warn_on_implicit_undefined_query_parameter_behavior

      prefix = @configuration.prefix
      prefix = prefix.call if prefix.is_a?(Proc)
      {
        'ROUTES_OBJECT'       => routes_object,
        'DEPRECATED_FALSE_PARAMETER_BEHAVIOR' => @configuration.deprecated_false_parameter_behavior,
        'DEPRECATED_NIL_QUERY_PARAMETER_BEHAVIOR' => @configuration.deprecated_nil_query_parameter_behavior,
        'INCLUDE_UNDEFINED_QUERY_PARAMETERS' => json(@configuration.include_undefined_query_parameters != false),
        'DEFAULT_URL_OPTIONS' => json(@configuration.default_url_options),
        'PREFIX'              => json(prefix),
        'SPECIAL_OPTIONS_KEY' => json(@configuration.special_options_key),
        'SERIALIZER'          => @configuration.serializer || json(nil),
        'MODULE_TYPE'         => json(@configuration.module_type),
        'WRAPPER'             => wrapper_variable,
        "IMPORT_ROUTER"       => import_router_variable,
        "EMBED_ROUTER"        => embed_router_variable,
      }
    end

    sig { void }
    def warn_on_implicit_undefined_query_parameter_behavior
      return unless @configuration.include_undefined_query_parameters.nil?

      JsRoutes::Utils.deprecator.warn(
        "JsRoutes include_undefined_query_parameters is not configured. " \
        "Set JsRoutes.setup { |c| c.include_undefined_query_parameters = false } " \
        "to omit undefined query parameters, or set it to true to keep legacy nil serialization. " \
        "The default will change to false in a future release."
      )
    end

    sig { returns(String) }
    def embed_router_variable
      unless @configuration.use_package? || @configuration.modern?
        read_js(@configuration.router_source_file)
      else
        ""
      end
    end

    sig { returns(String) }
    def import_router_variable
      if @configuration.use_package?
        "import Router from '#{@configuration.package}'"
      elsif @configuration.modern?
        read_js(@configuration.router_source_file)
      else
        ""
      end
    end

    sig { returns(String) }
    def wrapper_variable
      case @configuration.module_type
      when 'ESM', 'PKG'
        'const __jsr = '
      when 'NIL'
        namespace = @configuration.namespace
        if namespace
          if namespace.include?('.')
            "#{namespace} = "
          else
            "(typeof window !== 'undefined' ? window : this).#{namespace} = "
          end
        else
          ''
        end
      else
        ''
      end
    end

    sig { returns(Application) }
    def application
      app = @configuration.application
      app.is_a?(Proc) ? app.call : app
    end

    sig { params(value: T.untyped).returns(String) }
    def json(value)
      JsRoutes.json(value)
    end

    sig {params(application: Application).returns(T::Array[JourneyRoute])}
    def routes_from(application)
      T.unsafe(application).routes.named_routes.to_h.values.sort_by(&:name)
    end

    sig { returns(String) }
    def routes_object
      return json({}) if @configuration.modern? || @configuration.pkg?
      properties = routes_list.map do |comment, name, body|
        "#{comment}#{name}: #{body}".indent(2)
      end
      "{\n" + properties.join(",\n\n") + "}\n"
    end

    sig { returns(T::Array[StringArray]) }
    def static_exports
      [:configure, :config, :serialize, :__route].map do |name|
        [
          "", name.to_s,
          @configuration.dts? ?
          "RouterExposedMethods['#{name}']" :
          "__jsr.#{name}"
        ]
      end
    end

    sig { returns(String) }
    def routes_export
      return "" unless @configuration.modern?
      [*static_exports, *routes_list].map do |comment, name, body|
        "#{comment}export const #{name}#{export_separator}#{body};\n\n"
      end.join
    end

    sig { returns(String) }
    def export_separator
      @configuration.dts? ? ': ' : ' = '
    end

    sig { returns(T::Array[StringArray]) }
    def routes_list
      routes_from(application).flat_map do |route|
        route_helpers_if_match(route) + mounted_app_routes(route)
      end
    end

    sig { params(route: JourneyRoute).returns(T::Array[StringArray]) }
    def mounted_app_routes(route)
      rails_engine_app = T.unsafe(app_from_route(route))
      if rails_engine_app.is_a?(Class) &&
          rails_engine_app < Rails::Engine && !route.path.anchored
        routes_from(rails_engine_app).flat_map do |engine_route|
          route_helpers_if_match(engine_route, route)
        end
      else
        []
      end
    end

    sig { params(route: JourneyRoute).returns(T.untyped) }
    def app_from_route(route)
      app = route.app
      # Rails Engine can use additional
      # ActionDispatch::Routing::Mapper::Constraints, which contain app
      if app.is_a?(T.unsafe(ActionDispatch::Routing::Mapper::Constraints))
        app.app
      else
        app
      end
    end

    sig { params(route: JourneyRoute, parent_route: T.nilable(JourneyRoute)).returns(T::Array[StringArray]) }
    def route_helpers_if_match(route, parent_route = nil)
      Route.new(@configuration, route, parent_route).helpers
    end
  end
end
