# typed: strict
require "action_dispatch/journey/route"
require "pathname"
require "sorbet-runtime"

module JsRoutes
  module Types
    extend T::Sig
    Literal = T.type_alias { T.any(String, Symbol) }
    Attributes = T.type_alias{T::Hash[Symbol, T.untyped]}
    JourneyRoute = T.type_alias{ActionDispatch::Journey::Route}
    RouteSpec = T.type_alias {T.untyped}
    Application = T.type_alias { T.any(T::Class[Rails::Engine], Rails::Application) }
    ApplicationCaller = T.type_alias { T.proc.returns(Application) }
    Clusivity = T.type_alias { T.any(Regexp, T::Array[Regexp]) }
    FileName = T.type_alias { T.any(String, Pathname, NilClass) }
    ConfigurationBlock = T.type_alias { T.proc.params(arg0: JsRoutes::Configuration).void }
  end
end
