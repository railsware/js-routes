// eslint-disable-next-line @typescript-eslint/no-unused-expressions
RubyVariables.IMPORT_ROUTER;
RubyVariables.WRAPPER(() => {
    var _a;
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
                    }
                    else {
                        if (Modules.references.CJS.isSupported()) {
                            try {
                                Modules.references.CJS.define(routes);
                            }
                            catch (error) {
                                if (error.name !== "TypeError")
                                    throw error;
                            }
                        }
                    }
                },
                isSupported() {
                    return (Modules.references.AMD.isSupported() ||
                        Modules.references.CJS.isSupported());
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
        },
        is_module_supported(name) {
            return this.references[name].isSupported();
        },
        ensure_module_supported(name) {
            if (!this.is_module_supported(name)) {
                throw new Error(`${name} is not supported by runtime`);
            }
        },
        define_module(name, module) {
            this.ensure_module_supported(name);
            this.references[name].define(module);
            return module;
        },
    };
    const router = new Router({
        prefix: RubyVariables.PREFIX,
        default_url_options: RubyVariables.DEFAULT_URL_OPTIONS,
        special_options_key: RubyVariables.SPECIAL_OPTIONS_KEY,
        serializer: (_a = RubyVariables.SERIALIZER) !== null && _a !== void 0 ? _a : undefined,
        deprecated_false_parameter_behavior: RubyVariables.DEPRECATED_FALSE_PARAMETER_BEHAVIOR,
        deprecated_nil_query_parameter_behavior: RubyVariables.DEPRECATED_NIL_QUERY_PARAMETER_BEHAVIOR,
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
export {};
