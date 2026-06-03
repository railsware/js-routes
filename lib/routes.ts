import type {
  Serializer,
  Collection,
  RouteParameters,
  RouteHelper,
  RouterConstructor,
  RouterExposedMethods,
} from "./router";

type ModuleType = "CJS" | "AMD" | "UMD" | "ESM" | "DTS" | "NIL" | "PKG";

type RouteHelpers = Collection<RouteHelper>;

declare const Router: RouterConstructor;

declare const RubyVariables: {
  PREFIX: string;
  DEPRECATED_FALSE_PARAMETER_BEHAVIOR: boolean;
  DEPRECATED_NIL_QUERY_PARAMETER_BEHAVIOR: boolean;
  INCLUDE_UNDEFINED_QUERY_PARAMETERS: boolean;
  SPECIAL_OPTIONS_KEY: string;
  DEFAULT_URL_OPTIONS: RouteParameters;
  SERIALIZER: Serializer | null;
  ROUTES_OBJECT: RouteHelpers;
  MODULE_TYPE: ModuleType;
  IMPORT_ROUTER: RouterConstructor;
  EMBED_ROUTER: RouterConstructor;
  WRAPPER: <T>(callback: T) => T;
};

// eslint-disable-next-line @typescript-eslint/no-unused-expressions
RubyVariables.IMPORT_ROUTER;

declare const define:
  | undefined
  | (((arg: unknown[], callback: () => unknown) => void) & { amd?: unknown });

declare const module: { exports: unknown } | undefined;

type ModuleDefinition = {
  define: (routes: RouterExposedMethods) => void;
  isSupported: () => boolean;
};

RubyVariables.WRAPPER((): RouterExposedMethods => {
  // eslint-disable-next-line @typescript-eslint/no-unused-expressions
  RubyVariables.EMBED_ROUTER;
  const Modules = {
    references: {
      CJS: {
        define(routes) {
          if (module) {
            // Some javascript processors (like vite/rolldown)
            // warn on using module dot exports in an ESM module.
            // This just obfuscates that assignment a little so
            // users don't get a warning they can't fix.
            const _mod = module;
            _mod.exports = routes;
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
          if (Modules.references.AMD.isSupported()) {
            Modules.references.AMD.define(routes);
          } else {
            if (Modules.references.CJS.isSupported()) {
              try {
                Modules.references.CJS.define(routes);
              } catch (error) {
                if ((error as Error).name !== "TypeError") throw error;
              }
            }
          }
        },
        isSupported() {
          return (
            Modules.references.AMD.isSupported() ||
            Modules.references.CJS.isSupported()
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
          // Defined using RubyVariables . WRAPPER
        },
        isSupported() {
          return true;
        },
      },
      DTS: {
        // Acts the same as ESM
        define(routes) {
          Modules.references.ESM.define(routes);
        },
        isSupported() {
          return Modules.references.ESM.isSupported();
        },
      },
      PKG: {
        // Acts the same as ESM
        define() {
          Modules.references.ESM.define(new Router());
        },
        isSupported() {
          return Modules.references.ESM.isSupported();
        },
      },
    } as Record<ModuleType, ModuleDefinition>,

    is_module_supported(name: ModuleType): boolean {
      return this.references[name].isSupported();
    },

    ensure_module_supported(name: ModuleType): void {
      if (!this.is_module_supported(name)) {
        throw new Error(`${name} is not supported by runtime`);
      }
    },

    define_module(
      name: ModuleType,
      module: RouterExposedMethods,
    ): RouterExposedMethods {
      this.ensure_module_supported(name);
      this.references[name].define(module);
      return module;
    },
  };

  const router = new Router({
    prefix: RubyVariables.PREFIX,
    default_url_options: RubyVariables.DEFAULT_URL_OPTIONS,
    special_options_key: RubyVariables.SPECIAL_OPTIONS_KEY,
    serializer: RubyVariables.SERIALIZER ?? undefined,
    deprecated_false_parameter_behavior:
      RubyVariables.DEPRECATED_FALSE_PARAMETER_BEHAVIOR,
    deprecated_nil_query_parameter_behavior:
      RubyVariables.DEPRECATED_NIL_QUERY_PARAMETER_BEHAVIOR,
    include_undefined_query_parameters:
      RubyVariables.INCLUDE_UNDEFINED_QUERY_PARAMETERS,
  });

  const __route = router.__route.bind(router);

  return Modules.define_module(RubyVariables.MODULE_TYPE, {
    __route,
    configure: router.configure.bind(router),
    config: router.config.bind(router),
    serialize: router.serialize.bind(router),
    ...RubyVariables.ROUTES_OBJECT,
  });
})();
