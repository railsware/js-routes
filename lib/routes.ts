type Optional<T> = { [P in keyof T]?: T[P] | null };
type Collection<T> = Record<string, T>;

type BaseRouteParameter = string | boolean | Date | number;
type MethodRouteParameter = BaseRouteParameter | (() => BaseRouteParameter);
type ModelRouteParameter =
  | { id: MethodRouteParameter }
  | { to_param: MethodRouteParameter }
  | { toParam: MethodRouteParameter };
type RequiredRouteParameter = BaseRouteParameter | ModelRouteParameter;
type OptionalRouteParameter = undefined | null | RequiredRouteParameter;
type QueryRouteParameter =
  | OptionalRouteParameter
  | QueryRouteParameter[]
  | { [k: string]: QueryRouteParameter };
type RouteParameters = Collection<QueryRouteParameter>;

type Serializable = Collection<unknown>;
type Serializer = (value: Serializable) => string;
type RouteHelperExtras = {
  requiredParams(): string[];
  toString(): string;
};

type RequiredParameters<T extends number> = T extends 1
  ? [RequiredRouteParameter]
  : T extends 2
  ? [RequiredRouteParameter, RequiredRouteParameter]
  : T extends 3
  ? [RequiredRouteParameter, RequiredRouteParameter, RequiredRouteParameter]
  : T extends 4
  ? [
      RequiredRouteParameter,
      RequiredRouteParameter,
      RequiredRouteParameter,
      RequiredRouteParameter
    ]
  : RequiredRouteParameter[];

type RouteHelperOptions = RouteOptions & Collection<OptionalRouteParameter>;

type RouteHelper<T extends number = number> = ((
  ...args: [...RequiredParameters<T>, RouteHelperOptions]
) => string) &
  RouteHelperExtras;

type RouteHelpers = Collection<RouteHelper>;

type Configuration = {
  prefix: string;
  default_url_options: RouteParameters;
  special_options_key: string;
  serializer: Serializer;
};

interface RouterExposedMethods {
  config(): Configuration;
  configure(arg: Partial<Configuration>): Configuration;
  serialize: Serializer;
}

type KeywordUrlOptions = Optional<{
  host: string;
  protocol: string;
  subdomain: string;
  port: string | number;
  anchor: string;
  trailing_slash: boolean;
  params: RouteParameters;
}>;

type RouteOptions = KeywordUrlOptions & RouteParameters;

type PartsTable = Collection<{ r?: boolean; d?: OptionalRouteParameter }>;

type ModuleType = "CJS" | "AMD" | "UMD" | "ESM" | "DTS" | "NIL";

declare const RubyVariables: {
  PREFIX: string;
  DEPRECATED_FALSE_PARAMETER_BEHAVIOR: boolean;
  SPECIAL_OPTIONS_KEY: string;
  DEFAULT_URL_OPTIONS: RouteParameters;
  SERIALIZER: Serializer;
  ROUTES_OBJECT: RouteHelpers;
  MODULE_TYPE: ModuleType;
  WRAPPER: <T>(callback: T) => T;
};

declare const define:
  | undefined
  | (((arg: unknown[], callback: () => unknown) => void) & { amd?: unknown });

declare const module: { exports: unknown } | undefined;

// eslint-disable-next-line
RubyVariables.WRAPPER(
  // eslint-disable-next-line
  (): RouterExposedMethods => {
    const hasProp = (value: unknown, key: string): boolean =>
      Object.prototype.hasOwnProperty.call(value, key);
    enum NodeTypes {
      GROUP = 1,
      CAT = 2,
      SYMBOL = 3,
      OR = 4,
      STAR = 5,
      LITERAL = 6,
      SLASH = 7,
      DOT = 8,
    }
    type RouteNodes = {
      [NodeTypes.GROUP]: { left: RouteTree; right: never };
      [NodeTypes.STAR]: { left: RouteTree; right: never };
      [NodeTypes.LITERAL]: { left: string; right: never };
      [NodeTypes.SLASH]: { left: "/"; right: never };
      [NodeTypes.DOT]: { left: "."; right: never };
      [NodeTypes.CAT]: { left: RouteTree; right: RouteTree };
      [NodeTypes.SYMBOL]: { left: string; right: never };
    };
    type RouteNode<T extends keyof RouteNodes> = [
      T,
      RouteNodes[T]["left"],
      RouteNodes[T]["right"]
    ];
    type RouteTree = {
      [T in keyof RouteNodes]: RouteNode<T>;
    }[keyof RouteNodes];

    const isBrowser = typeof window !== "undefined";
    type ModuleDefinition = {
      define: (routes: RouterExposedMethods) => void;
      isSupported: () => boolean;
    };

    const UnescapedSpecials = "-._~!$&'()*+,;=:@"
      .split("")
      .map((s) => s.charCodeAt(0));
    const UnescapedRanges = [
      ["a", "z"],
      ["A", "Z"],
      ["0", "9"],
    ].map((range) => range.map((s) => s.charCodeAt(0)));

    const ModuleReferences: Record<ModuleType, ModuleDefinition> = {
      CJS: {
        define(routes) {
          if (module) {
            module.exports = routes;
          }
        },
        isSupported() {
          return typeof module === "object";
        },
      },
      AMD: {
        define(routes) {
          if (define) {
            define([], function () {
              return routes;
            });
          }
        },
        isSupported() {
          return typeof define === "function" && !!define.amd;
        },
      },
      UMD: {
        define(routes) {
          if (ModuleReferences.AMD.isSupported()) {
            ModuleReferences.AMD.define(routes);
          } else {
            if (ModuleReferences.CJS.isSupported()) {
              try {
                ModuleReferences.CJS.define(routes);
              } catch (error) {
                if (error.name !== "TypeError") throw error;
              }
            }
          }
        },
        isSupported() {
          return (
            ModuleReferences.AMD.isSupported() ||
            ModuleReferences.CJS.isSupported()
          );
        },
      },
      ESM: {
        define() {
          // Module can only be defined using ruby code generation
        },
        isSupported() {
          // Its impossible to check if "export" keyword is supported
          return true;
        },
      },
      NIL: {
        define() {
          // Defined using RubyVariables.WRAPPER
        },
        isSupported() {
          return true;
        },
      },
      DTS: {
        // Acts the same as ESM
        define(routes) {
          ModuleReferences.ESM.define(routes);
        },
        isSupported() {
          return ModuleReferences.ESM.isSupported();
        },
      },
    };

    class ParametersMissing extends Error {
      readonly keys: string[];
      constructor(...keys: string[]) {
        super(`Route missing required keys: ${keys.join(", ")}`);
        this.keys = keys;
        Object.setPrototypeOf(this, Object.getPrototypeOf(this));
        this.name = ParametersMissing.name;
      }
    }

    const ReservedOptions = [
      "anchor",
      "trailing_slash",
      "subdomain",
      "host",
      "port",
      "protocol",
    ] as const;
    type ReservedOption = (typeof ReservedOptions)[any];

    class UtilsClass {
      configuration: Configuration = {
        prefix: RubyVariables.PREFIX,
        default_url_options: RubyVariables.DEFAULT_URL_OPTIONS,
        special_options_key: RubyVariables.SPECIAL_OPTIONS_KEY,
        serializer:
          RubyVariables.SERIALIZER || this.default_serializer.bind(this),
      };

      default_serializer(value: unknown, prefix?: string | null): string {
        if (this.is_nullable(value)) {
          return "";
        }
        if (!prefix && !this.is_object(value)) {
          throw new Error("Url parameters should be a javascript hash");
        }
        prefix = prefix || "";
        const result: string[] = [];
        if (this.is_array(value)) {
          for (const element of value) {
            result.push(this.default_serializer(element, prefix + "[]"));
          }
        } else if (this.is_object(value)) {
          for (let key in value) {
            if (!hasProp(value, key)) continue;
            let prop = value[key];
            if (this.is_nullable(prop) && prefix) {
              prop = "";
            }
            if (this.is_not_nullable(prop)) {
              if (prefix) {
                key = prefix + "[" + key + "]";
              }
              result.push(this.default_serializer(prop, key));
            }
          }
        } else {
          if (this.is_not_nullable(value)) {
            result.push(
              encodeURIComponent(prefix) + "=" + encodeURIComponent("" + value)
            );
          }
        }
        return result.join("&");
      }

      serialize(object: Serializable): string {
        return this.configuration.serializer(object);
      }

      extract_options(
        number_of_params: number,
        args: OptionalRouteParameter[]
      ): {
        args: OptionalRouteParameter[];
        options: RouteOptions;
      } {
        const last_el = args[args.length - 1];
        if (
          (args.length > number_of_params && last_el === 0) ||
          (this.is_object(last_el) &&
            !this.looks_like_serialized_model(last_el))
        ) {
          if (this.is_object(last_el)) {
            delete last_el[this.configuration.special_options_key];
          }
          return {
            args: args.slice(0, args.length - 1),
            options: last_el as unknown as RouteOptions,
          };
        } else {
          return { args, options: {} };
        }
      }

      looks_like_serialized_model(
        object: unknown
      ): object is ModelRouteParameter {
        return (
          this.is_object(object) &&
          !(this.configuration.special_options_key in object) &&
          ("id" in object || "to_param" in object || "toParam" in object)
        );
      }

      path_identifier(object: QueryRouteParameter): string {
        const result = this.unwrap_path_identifier(object);
        return this.is_nullable(result) ||
          (RubyVariables.DEPRECATED_FALSE_PARAMETER_BEHAVIOR &&
            result === false)
          ? ""
          : "" + result;
      }

      unwrap_path_identifier(object: QueryRouteParameter): unknown {
        let result: unknown = object;
        if (!this.is_object(object)) {
          return object;
        }
        if ("to_param" in object) {
          result = object.to_param;
        } else if ("toParam" in object) {
          result = object.toParam;
        } else if ("id" in object) {
          result = object.id;
        } else {
          result = object;
        }
        return this.is_callable(result) ? result.call(object) : result;
      }

      partition_parameters(
        parts: string[],
        required_params: string[],
        default_options: RouteParameters,
        call_arguments: OptionalRouteParameter[]
      ): {
        keyword_parameters: KeywordUrlOptions;
        query_parameters: RouteParameters;
      } {
        // eslint-disable-next-line prefer-const
        let { args, options } = this.extract_options(
          parts.length,
          call_arguments
        );
        if (args.length > parts.length) {
          throw new Error("Too many parameters provided for path");
        }
        let use_all_parts = args.length > required_params.length;
        const parts_options: RouteParameters = {
          ...this.configuration.default_url_options,
        };
        for (const key in options) {
          const value = options[key];
          if (!hasProp(options, key)) continue;
          use_all_parts = true;
          if (parts.includes(key)) {
            parts_options[key] = value;
          }
        }
        options = {
          ...this.configuration.default_url_options,
          ...default_options,
          ...options,
        };

        const keyword_parameters: KeywordUrlOptions = {};
        let query_parameters: RouteParameters = {};
        for (const key in options) {
          if (!hasProp(options, key)) continue;
          const value = options[key];
          if (key === "params") {
            if (this.is_object(value)) {
              query_parameters = {
                ...query_parameters,
                ...(value as RouteParameters),
              };
            } else {
              throw new Error("params value should always be an object");
            }
          } else if (this.is_reserved_option(key)) {
            keyword_parameters[key] = value as any;
          } else {
            if (
              !this.is_nullable(value) &&
              (value !== default_options[key] || required_params.includes(key))
            ) {
              query_parameters[key] = value;
            }
          }
        }
        const route_parts = use_all_parts ? parts : required_params;
        let i = 0;
        for (const part of route_parts) {
          if (i < args.length) {
            const value = args[i];
            if (!hasProp(parts_options, part)) {
              query_parameters[part] = value;
              ++i;
            }
          }
        }
        return { keyword_parameters, query_parameters };
      }

      build_route(
        parts: string[],
        required_params: string[],
        default_options: RouteParameters,
        route: RouteTree,
        absolute: boolean,
        args: OptionalRouteParameter[]
      ): string {
        const { keyword_parameters, query_parameters } =
          this.partition_parameters(
            parts,
            required_params,
            default_options,
            args
          );
        const missing_params = required_params.filter(
          (param) =>
            !hasProp(query_parameters, param) ||
            this.is_nullable(query_parameters[param])
        );
        if (missing_params.length) {
          throw new ParametersMissing(...missing_params);
        }
        let result = this.get_prefix() + this.visit(route, query_parameters);
        if (keyword_parameters.trailing_slash) {
          result = result.replace(/(.*?)[/]?$/, "$1/");
        }
        const url_params = this.serialize(query_parameters);
        if (url_params.length) {
          result += "?" + url_params;
        }
        if (keyword_parameters.anchor) {
          result += "#" + keyword_parameters.anchor;
        }
        if (absolute) {
          result = this.route_url(keyword_parameters) + result;
        }
        return result;
      }

      visit(
        route: RouteTree,
        parameters: RouteParameters,
        optional = false
      ): string {
        switch (route[0]) {
          case NodeTypes.GROUP:
            return this.visit(route[1], parameters, true);
          case NodeTypes.CAT:
            return this.visit_cat(route, parameters, optional);
          case NodeTypes.SYMBOL:
            return this.visit_symbol(route, parameters, optional);
          case NodeTypes.STAR:
            return this.visit_globbing(route[1], parameters, true);
          case NodeTypes.LITERAL:
          case NodeTypes.SLASH:
          case NodeTypes.DOT:
            return route[1];
          default:
            throw new Error("Unknown Rails node type");
        }
      }

      is_not_nullable<T>(object: T): object is NonNullable<T> {
        return !this.is_nullable(object);
      }

      is_nullable(object: unknown): object is null | undefined {
        return object === undefined || object === null;
      }

      visit_cat(
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        [_type, left, right]: RouteNode<NodeTypes.CAT>,
        parameters: RouteParameters,
        optional: boolean
      ): string {
        const left_part = this.visit(left, parameters, optional);
        let right_part = this.visit(right, parameters, optional);
        if (
          optional &&
          ((this.is_optional_node(left[0]) && !left_part) ||
            (this.is_optional_node(right[0]) && !right_part))
        ) {
          return "";
        }
        // if left_part ends on '/' and right_part starts on '/'
        if (left_part[left_part.length - 1] === "/" && right_part[0] === "/") {
          // strip slash from right_part
          // to prevent double slash
          right_part = right_part.substring(1);
        }
        return left_part + right_part;
      }

      visit_symbol(
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        [_type, key]: RouteNode<NodeTypes.SYMBOL>,
        parameters: RouteParameters,
        optional: boolean
      ): string {
        const value = this.path_identifier(parameters[key]);
        delete parameters[key];
        if (value.length) {
          return this.encode_segment(value);
        }
        if (optional) {
          return "";
        } else {
          throw new ParametersMissing(key);
        }
      }

      encode_segment(segment: string): string {
        if (segment.match(/^[a-zA-Z0-9-]$/)) {
          // Performance optimization for 99% of cases
          return segment;
        }
        return (segment.match(/./gu) || [])
          .map((ch) => {
            const code = ch.charCodeAt(0);
            if (
              UnescapedRanges.find(
                (range) => code >= range[0] && code <= range[1]
              ) ||
              UnescapedSpecials.includes(code)
            ) {
              return ch;
            } else {
              return encodeURIComponent(ch);
            }
          })
          .join("");
      }

      is_optional_node(node: NodeTypes): boolean {
        return [NodeTypes.STAR, NodeTypes.SYMBOL, NodeTypes.CAT].includes(node);
      }

      build_path_spec(route: RouteTree, wildcard = false): string {
        let key: string;
        switch (route[0]) {
          case NodeTypes.GROUP:
            return `(${this.build_path_spec(route[1])})`;
          case NodeTypes.CAT:
            return (
              this.build_path_spec(route[1]) + this.build_path_spec(route[2])
            );
          case NodeTypes.STAR:
            return this.build_path_spec(route[1], true);
          case NodeTypes.SYMBOL:
            key = route[1];
            if (wildcard) {
              return (key.startsWith("*") ? "" : "*") + key;
            } else {
              return ":" + key;
            }
            break;
          case NodeTypes.SLASH:
          case NodeTypes.DOT:
          case NodeTypes.LITERAL:
            return route[1];
          default:
            throw new Error("Unknown Rails node type");
        }
      }

      visit_globbing(
        route: RouteTree,
        parameters: RouteParameters,
        optional: boolean
      ): string {
        const key = route[1] as string;
        let value = parameters[key];
        delete parameters[key];
        if (this.is_nullable(value)) {
          return this.visit(route, parameters, optional);
        }
        if (this.is_array(value)) {
          value = value.join("/");
        }
        const result = this.path_identifier(value as any);
        return encodeURI(result);
      }

      get_prefix(): string {
        const prefix = this.configuration.prefix;
        return prefix.match("/$")
          ? prefix.substring(0, prefix.length - 1)
          : prefix;
      }

      route(
        parts_table: PartsTable,
        route_spec: RouteTree,
        absolute = false
      ): RouteHelper {
        const required_params: string[] = [];
        const parts: string[] = [];
        const default_options: RouteParameters = {};
        for (const [part, { r: required, d: value }] of Object.entries(
          parts_table
        )) {
          parts.push(part);
          if (required) {
            required_params.push(part);
          }
          if (this.is_not_nullable(value)) {
            default_options[part] = value;
          }
        }
        const result = (...args: OptionalRouteParameter[]): string => {
          return this.build_route(
            parts,
            required_params,
            default_options,
            route_spec,
            absolute,
            args
          );
        };
        result.requiredParams = () => required_params;
        result.toString = () => {
          return this.build_path_spec(route_spec);
        };
        return result as any;
      }

      route_url(route_defaults: KeywordUrlOptions): string {
        const hostname = route_defaults.host || this.current_host();
        if (!hostname) {
          return "";
        }
        const subdomain = route_defaults.subdomain
          ? route_defaults.subdomain + "."
          : "";
        const protocol = route_defaults.protocol || this.current_protocol();
        let port =
          route_defaults.port ||
          (!route_defaults.host ? this.current_port() : undefined);
        port = port ? ":" + port : "";
        return protocol + "://" + subdomain + hostname + port;
      }

      current_host(): string {
        return (isBrowser && window?.location?.hostname) || "";
      }

      current_protocol(): string {
        return (
          (isBrowser && window?.location?.protocol?.replace(/:$/, "")) || "http"
        );
      }

      current_port(): string {
        return (isBrowser && window?.location?.port) || "";
      }

      is_object(value: unknown): value is Collection<unknown> {
        return (
          typeof value === "object" &&
          Object.prototype.toString.call(value) === "[object Object]"
        );
      }

      is_array<T>(object: unknown | T[]): object is T[] {
        return object instanceof Array;
      }

      is_callable(object: unknown): object is Function {
        return typeof object === "function" && !!object.call;
      }

      is_reserved_option(key: unknown): key is ReservedOption {
        return ReservedOptions.includes(key as any);
      }

      configure(new_config: Partial<Configuration>): Configuration {
        this.configuration = { ...this.configuration, ...new_config };
        return this.configuration;
      }

      config(): Configuration {
        return { ...this.configuration };
      }

      is_module_supported(name: ModuleType): boolean {
        return ModuleReferences[name].isSupported();
      }

      ensure_module_supported(name: ModuleType): void {
        if (!this.is_module_supported(name)) {
          throw new Error(`${name} is not supported by runtime`);
        }
      }

      define_module(
        name: ModuleType,
        module: RouterExposedMethods
      ): RouterExposedMethods {
        this.ensure_module_supported(name);
        ModuleReferences[name].define(module);
        return module;
      }
    }

    const utils = new UtilsClass();

    // We want this helper name to be short
    const __jsr = {
      r(
        parts_table: PartsTable,
        route_spec: RouteTree,
        absolute?: boolean
      ): RouteHelper {
        return utils.route(parts_table, route_spec, absolute);
      },
    };

    return utils.define_module(RubyVariables.MODULE_TYPE, {
      ...__jsr,
      configure: (config: Partial<Configuration>) => {
        return utils.configure(config);
      },
      config: (): Configuration => {
        return utils.config();
      },
      serialize: (object: Serializable): string => {
        return utils.serialize(object);
      },
      ...RubyVariables.ROUTES_OBJECT,
    });
  }
)();
