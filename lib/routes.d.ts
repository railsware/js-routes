declare type RouteParameter = unknown;
declare type RouteParameters = Record<string, RouteParameter>;
declare type Serializer = (value: unknown) => string;
declare type RouteHelper = {
  (...args: RouteParameter[]): string;
  required_params: string[];
  toString(): string;
};
declare type RouteHelpers = Record<string, RouteHelper>;
declare type Configuration = {
  prefix: string;
  default_url_options: RouteParameters;
  special_options_key: string;
  serializer: Serializer;
};
declare type Optional<T> = {
  [P in keyof T]?: T[P] | null;
};
declare type RouterExposedMethods = {
  config(): Configuration;
  configure(arg: Partial<Configuration>): Configuration;
  serialize: Serializer;
};
declare type KeywordUrlOptions = Optional<{
  host: string;
  protocol: string;
  subdomain: string;
  port: string;
  anchor: string;
  trailing_slash: boolean;
}>;
declare type PartDescriptor = [string, boolean | undefined, unknown];
declare type ModuleType = "CJS" | "AMD" | "UMD";
declare const RubyVariables: {
  PREFIX: string;
  DEPRECATED_GLOBBING_BEHAVIOR: boolean;
  SPECIAL_OPTIONS_KEY: string;
  DEFAULT_URL_OPTIONS: RouteParameters;
  SERIALIZER: Serializer;
  NAMESPACE: string;
  ROUTES: RouteHelpers;
  MODULE_TYPE: ModuleType | null;
};
declare const define:
  | undefined
  | (((arg: unknown[], callback: () => unknown) => void) & {
      amd?: unknown;
    });
declare const module:
  | {
      exports: any;
    }
  | undefined;
