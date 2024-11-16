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
      if named_routes.empty?
        if application.is_a?(Rails::Application)
          if Rails.version >= "8.0.0"
            application.reload_routes_unless_loaded
          else
            application.reload_routes!
          end
        end
      end
      content = File.read(@configuration.source_file)

      unless @configuration.dts?
        content = js_variables.inject(content) do |js, (key, value)|
          js.gsub!("RubyVariables.#{key}", value.to_s) ||
          raise("Missing key #{key} in JS template")
        end
      end
      content + routes_export + prevent_types_export
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
    def remove!
      path = Rails.root.join(@configuration.output_file)
      FileUtils.rm_rf(path)
      FileUtils.rm_rf(path.sub(%r{\.js\z}, '.d.ts'))
    end

    protected

    sig { returns(T::Hash[String, String]) }
    def js_variables
      version = Rails.version
      prefix = @configuration.prefix
      prefix = prefix.call if prefix.is_a?(Proc)
      {
        'GEM_VERSION'         => JsRoutes::VERSION,
        'ROUTES_OBJECT'       => routes_object,
        'RAILS_VERSION'       => ::Rails.version,
        'DEPRECATED_GLOBBING_BEHAVIOR' => version >= '4.0.0' && version < '4.1.0',
        'DEPRECATED_FALSE_PARAMETER_BEHAVIOR' => version < '7.0.0',
        'APP_CLASS'           => application.class.to_s,
        'DEFAULT_URL_OPTIONS' => json(@configuration.default_url_options),
        'PREFIX'              => json(prefix),
        'SPECIAL_OPTIONS_KEY' => json(@configuration.special_options_key),
        'SERIALIZER'          => @configuration.serializer || json(nil),
        'MODULE_TYPE'         => json(@configuration.module_type),
        'WRAPPER'             => wrapper_variable,
      }
    end

    sig { returns(String) }
    def wrapper_variable
      case @configuration.module_type
      when 'ESM'
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
      @configuration.application.call
    end

    sig { params(value: T.untyped).returns(String) }
    def json(value)
      JsRoutes.json(value)
    end

    sig { returns(T::Hash[Symbol, JourneyRoute]) }
    def named_routes
      T.unsafe(application).routes.named_routes.to_h
    end

    sig { returns(String) }
    def routes_object
      return json({}) if @configuration.modern?
      properties = routes_list.map do |comment, name, body|
        "#{comment}#{name}: #{body}".indent(2)
      end
      "{\n" + properties.join(",\n\n") + "}\n"
    end

    sig { returns(T::Array[StringArray]) }
    def static_exports
      [:configure, :config, :serialize].map do |name|
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
    def prevent_types_export
      return "" unless @configuration.dts?
      <<-JS
// By some reason this line prevents all types in a file
// from being automatically exported
export {};
      JS
    end

    sig { returns(String) }
    def export_separator
      @configuration.dts? ? ': ' : ' = '
    end

    sig { returns(T::Array[StringArray]) }
    def routes_list
      named_routes.sort_by(&:first).flat_map do |_, route|
        route_helpers_if_match(route) + mounted_app_routes(route)
      end
    end

    sig { params(route: JourneyRoute).returns(T::Array[StringArray]) }
    def mounted_app_routes(route)
      rails_engine_app = T.unsafe(app_from_route(route))
      if rails_engine_app.is_a?(Class) &&
          rails_engine_app < Rails::Engine && !route.path.anchored
        rails_engine_app.routes.named_routes.flat_map do |_, engine_route|
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
      if app.is_a?(ActionDispatch::Routing::Mapper::Constraints)
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
