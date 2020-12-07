declare type RouteParameter = unknown;
declare type RouteParameters = Record<string, RouteParameter>;
declare type Serializer = (value: unknown) => string;
export declare type Configuration = {
    prefix: string;
    default_url_options: RouteParameters;
    special_options_key: string;
    serializer: Serializer;
};
export {};
