type Optional<T> = {
    [P in keyof T]?: T[P] | null;
};
type Collection<T> = Record<string, T>;
type BaseRouteParameter = string | boolean | Date | number | bigint;
type MethodRouteParameter = BaseRouteParameter | (() => BaseRouteParameter);
type ModelRouteParameter = {
    id: MethodRouteParameter;
} | {
    to_param: MethodRouteParameter;
} | {
    toParam: MethodRouteParameter;
};
type RequiredRouteParameter = BaseRouteParameter | ModelRouteParameter;
type OptionalRouteParameter = undefined | null | RequiredRouteParameter;
type QueryRouteParameter = OptionalRouteParameter | QueryRouteParameter[] | {
    [k: string]: QueryRouteParameter;
};
type RouteParameters = Collection<QueryRouteParameter>;
type Serializable = Collection<unknown>;
type Serializer = (value: Serializable) => string;
type RouteHelperExtras = {
    requiredParams(): string[];
    toString(): string;
};
type RequiredParameters<T extends number> = T extends 1 ? [RequiredRouteParameter] : T extends 2 ? [RequiredRouteParameter, RequiredRouteParameter] : T extends 3 ? [RequiredRouteParameter, RequiredRouteParameter, RequiredRouteParameter] : T extends 4 ? [
    RequiredRouteParameter,
    RequiredRouteParameter,
    RequiredRouteParameter,
    RequiredRouteParameter
] : RequiredRouteParameter[];
type RouteHelperOptions = RouteOptions & Collection<OptionalRouteParameter>;
type RouteHelper<T extends number = number> = ((...args: [...RequiredParameters<T>, RouteHelperOptions]) => string) & RouteHelperExtras;
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
    script_name: string;
    params: RouteParameters;
}>;
type RouteOptions = KeywordUrlOptions & RouteParameters;
type PartsTable = Collection<{
    r?: boolean;
    d?: OptionalRouteParameter;
}>;
type ModuleType = "CJS" | "AMD" | "UMD" | "ESM" | "DTS" | "NIL";
declare const RubyVariables: {
    PREFIX: string;
    DEPRECATED_FALSE_PARAMETER_BEHAVIOR: boolean;
    DEPRECATED_NIL_QUERY_PARAMETER_BEHAVIOR: boolean;
    SPECIAL_OPTIONS_KEY: string;
    DEFAULT_URL_OPTIONS: RouteParameters;
    SERIALIZER: Serializer;
    ROUTES_OBJECT: RouteHelpers;
    MODULE_TYPE: ModuleType;
    WRAPPER: <T>(callback: T) => T;
};
declare const define: undefined | (((arg: unknown[], callback: () => unknown) => void) & {
    amd?: unknown;
});
declare const module: {
    exports: unknown;
} | undefined;
export const configure: RouterExposedMethods['configure'];

export const config: RouterExposedMethods['config'];

export const serialize: RouterExposedMethods['serialize'];

/**
 * Generates rails route to
 * /inboxes/:inbox_id/messages/:message_id/attachments/:id
 * @param {any} inbox_id
 * @param {any} message_id
 * @param {any} id
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inbox_message_attachment_path: ((
  inbox_id: RequiredRouteParameter,
  message_id: RequiredRouteParameter,
  id: RequiredRouteParameter,
  options?: RouteOptions
) => string) & RouteHelperExtras;

/**
 * Generates rails route to
 * /inboxes(.:format)
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inboxes_path: ((
  options?: {format?: OptionalRouteParameter} & RouteOptions
) => string) & RouteHelperExtras;

// By some reason this line prevents all types in a file
// from being automatically exported
export {};
