type Optional<T> = {
    [P in keyof T]?: T[P] | null;
};
export type Collection<T> = Record<string, T>;
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
export type RouteParameters = Collection<QueryRouteParameter>;
type Serializable = Collection<unknown>;
export type Serializer = (value: Serializable) => string;
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
export type RouteHelper<T extends number = number> = ((...args: [...RequiredParameters<T>, RouteHelperOptions]) => string) & RouteHelperExtras;
type Configuration = {
    prefix: string;
    default_url_options: RouteParameters;
    special_options_key: string;
    serializer: Serializer;
    deprecated_false_parameter_behavior: boolean;
    deprecated_nil_query_parameter_behavior: boolean;
};
export interface RouterExposedMethods {
    config(): Configuration;
    configure(arg: Partial<Configuration>): Configuration;
    serialize: Serializer;
    __route(...args: unknown[]): RouteHelper;
}
export interface RouterConstructor {
    new (config?: Partial<Configuration>): RouterExposedMethods;
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
export {};
