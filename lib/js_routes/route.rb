# typed: strict

require "js_routes/types"
require "action_dispatch/journey/route"

module JsRoutes
  class Route #:nodoc:
    include JsRoutes::Types
    extend T::Sig

    FILTERED_DEFAULT_PARTS = T.let([:controller, :action].freeze, SymbolArray)
    URL_OPTIONS = T.let([:protocol, :domain, :host, :port, :subdomain].freeze, SymbolArray)
    NODE_TYPES = T.let({
      GROUP: 1,
      CAT: 2,
      SYMBOL: 3,
      OR: 4,
      STAR: 5,
      LITERAL: 6,
      SLASH: 7,
      DOT: 8
    }.freeze, T::Hash[Symbol, Integer])

    sig {returns(JsRoutes::Configuration)}
    attr_reader :configuration

    sig {returns(JourneyRoute)}
    attr_reader :route

    sig {returns(T.nilable(JourneyRoute))}
    attr_reader :parent_route

    sig { params(configuration: JsRoutes::Configuration, route: JourneyRoute, parent_route: T.nilable(JourneyRoute)).void }
    def initialize(configuration, route, parent_route = nil)
      @configuration = configuration
      @route = route
      @parent_route = parent_route
    end

    sig { returns(T::Array[StringArray]) }
    def helpers
      helper_types.map do |absolute|
        [ documentation, helper_name(absolute), body(absolute) ]
      end
    end

    sig {returns(T::Array[T::Boolean])}
    def helper_types
      return [] unless match_configuration?
      @configuration.url_links ? [true, false] : [false]
    end

    sig { params(absolute: T::Boolean).returns(String) }
    def body(absolute)
      if @configuration.dts?
        definition_body
      else
        # For tree-shaking ESM, add a #__PURE__ comment informing Webpack/minifiers that the call to `__jsr.r`
        # has no side-effects (e.g. modifying global variables) and is safe to remove when unused.
        # https://webpack.js.org/guides/tree-shaking/#clarifying-tree-shaking-and-sidyeeffects
        pure_comment = @configuration.esm? ? '/*#__PURE__*/ ' : ''
        "#{pure_comment}__jsr.r(#{arguments(absolute).map{|a| json(a)}.join(', ')})"
      end
    end

    sig { returns(String) }
    def definition_body
      options_type = optional_parts_type ? "#{optional_parts_type} & RouteOptions" : "RouteOptions"
      args = required_parts.map{|p| "#{apply_case(p)}: RequiredRouteParameter"}
      args << "options?: #{options_type}"
      "((\n#{args.join(",\n").indent(2)}\n) => string) & RouteHelperExtras"
    end

    sig { returns(T.nilable(String)) }
    def optional_parts_type
      return nil if optional_parts.empty?
      @optional_parts_type ||= T.let(
        "{" + optional_parts.map {|p| "#{p}?: OptionalRouteParameter"}.join(', ') + "}",
        T.nilable(String)
      )
    end

    protected


    sig { params(absolute: T::Boolean).returns(UntypedArray) }
    def arguments(absolute)
      absolute ? [*base_arguments, true] : base_arguments
    end

    sig { returns(T::Boolean) }
    def match_configuration?
      !match?(@configuration.exclude) && match?(@configuration.include)
    end

    sig { returns(T.nilable(String)) }
    def base_name
      @base_name ||= T.let(parent_route ?
        [parent_route&.name, route.name].join('_') : route.name, T.nilable(String))
    end

    sig { returns(T.nilable(RouteSpec)) }
    def parent_spec
      parent_route&.path&.spec
    end

    sig { returns(RouteSpec) }
    def spec
      route.path.spec
    end

    sig { params(value: T.untyped).returns(String) }
    def json(value)
      JsRoutes.json(value)
    end

    sig { params(absolute: T::Boolean).returns(String) }
    def helper_name(absolute)
      suffix = absolute ? :url : @configuration.compact ? nil : :path
      apply_case(base_name, suffix)
    end

    sig { returns(String) }
    def documentation
      return '' unless @configuration.documentation
      <<-JS
/**
 * Generates rails route to
 * #{parent_spec}#{spec}#{documentation_params}
 * @param {object | undefined} options
 * @returns {string} route path
 */
JS
    end

    sig { returns(SymbolArray) }
    def required_parts
      route.required_parts
    end

    sig { returns(SymbolArray) }
    def optional_parts
      route.path.optional_names
    end

    sig { returns(UntypedArray) }
    def base_arguments
      @base_arguments ||= T.let([parts_table, serialize(spec, parent_spec)], T.nilable(UntypedArray))
    end

    sig { returns(T::Hash[Symbol, Options]) }
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

    sig { returns(String) }
    def documentation_params
      required_parts.map do |param|
        "\n * @param {any} #{apply_case(param)}"
      end.join
    end

    sig { params(matchers: Clusivity).returns(T::Boolean) }
    def match?(matchers)
      Array(matchers).any? { |regex| base_name =~ regex }
    end

    sig { params(values: T.nilable(Literal)).returns(String) }
    def apply_case(*values)
      value = values.compact.map(&:to_s).join('_')
      @configuration.camel_case ? value.camelize(:lower) : value
    end

    # This function serializes Journey route into JSON structure
    # We do not use Hash for human readable serialization
    # And preffer Array serialization because it is shorter.
    # Routes.js file will be smaller.
    sig { params(spec: SpecNode, parent_spec: T.nilable(RouteSpec)).returns(T.nilable(T.any(UntypedArray, String))) }
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

    sig { params(spec: RouteSpec, parent_spec: T.nilable(RouteSpec)).returns(UntypedArray) }
    def serialize_spec(spec, parent_spec = nil)
      [
        NODE_TYPES[spec.type],
        serialize(spec.left, parent_spec),
        spec.respond_to?(:right) ? serialize(spec.right) : nil
      ].compact
    end
  end
end
