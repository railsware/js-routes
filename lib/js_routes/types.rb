# typed: strict
require "action_dispatch/journey/route"
require "pathname"
require "sorbet-runtime"

module JsRoutes
  module Types
    extend T::Sig

    UntypedArray = T.type_alias {T::Array[T.untyped]}
    StringArray = T.type_alias {T::Array[String]}
    SymbolArray = T.type_alias {T::Array[Symbol]}
    StringHash = T.type_alias { T::Hash[String, T.untyped] }
    Options = T.type_alias { T::Hash[Symbol, T.untyped] }
    SpecNode = T.type_alias { T.any(String, RouteSpec, NilClass) }
    Literal = T.type_alias { T.any(String, Symbol) }
    JourneyRoute = T.type_alias{ActionDispatch::Journey::Route}
    RouteSpec = T.type_alias {T.untyped}
    Application = T.type_alias { T.any(T::Class[Rails::Engine], Rails::Application) }
    ApplicationCaller = T.type_alias { T.any(Application, T.proc.returns(Application)) }
    Clusivity = T.type_alias { T.any(Regexp, T::Array[Regexp]) }
    FileName = T.type_alias { T.any(String, Pathname, NilClass) }
    ConfigurationBlock = T.type_alias { T.proc.params(arg0: JsRoutes::Configuration).void }
    Prefix = T.type_alias do
      T.any(T.proc.returns(String), String, NilClass)
    end

    module RackApp
      extend T::Sig
      extend T::Helpers

      interface!

      sig { abstract.params(input: StringHash).returns(UntypedArray) }
      def call(input); end
    end
  end
end
