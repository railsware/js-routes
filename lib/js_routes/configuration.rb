# typed: strict
require "pathname"
require "js_routes/types"

module JsRoutes
  class Configuration
    include JsRoutes::Types
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_accessor :namespace
    sig { returns(Clusivity) }
    attr_accessor :exclude
    sig { returns(Clusivity) }
    attr_accessor :include
    sig { returns(FileName) }
    attr_accessor :file
    sig { returns(Prefix) }
    attr_accessor :prefix
    sig { returns(T::Boolean) }
    attr_accessor :url_links
    sig { returns(T::Boolean) }
    attr_accessor :camel_case
    sig { returns(Options) }
    attr_accessor :default_url_options
    sig { returns(T::Boolean) }
    attr_accessor :compact
    sig { returns(T.nilable(String)) }
    attr_accessor :serializer
    sig { returns(Literal) }
    attr_accessor :special_options_key
    sig { returns(ApplicationCaller) }
    attr_accessor :application
    sig { returns(T::Boolean) }
    attr_accessor :documentation
    sig { returns(T.nilable(String)) }
    attr_accessor :module_type

    sig {params(attributes: T.nilable(Options)).void }
    def initialize(attributes = nil)
      @namespace = nil
      @exclude = T.let([], Clusivity)
      @include = T.let([//], Clusivity)
      @file = T.let(nil, FileName)
      @prefix = T.let(-> { Rails.application.config.relative_url_root || "" }, T.untyped)
      @url_links = T.let(false, T::Boolean)
      @camel_case = T.let(false, T::Boolean)
      @default_url_options = T.let(T.unsafe({}), Options)
      @compact = T.let(false, T::Boolean)
      @serializer = T.let(nil, T.nilable(String))
      @special_options_key = T.let("_options", Literal)
      @application = T.let(-> { Rails.application }, ApplicationCaller)
      @module_type = T.let('ESM', T.nilable(String))
      @documentation = T.let(true, T::Boolean)

      return unless attributes
      assign(attributes)
    end

    sig do
      params(
        attributes: Options,
      ).returns(JsRoutes::Configuration)
    end
    def assign(attributes)
      if attributes
        attributes.each do |attribute, value|
          public_send(:"#{attribute}=", value)
        end
      end
      normalize_and_verify
      self
    end

    sig { params(block: ConfigurationBlock).returns(T.self_type) }
    def setup(&block)
      tap(&block)
    end

    sig { params(attribute: Literal).returns(T.untyped) }
    def [](attribute)
      public_send(attribute)
    end

    sig { params(attributes: Options).returns(JsRoutes::Configuration) }
    def merge(attributes)
      clone.assign(attributes)
    end

    sig {returns(T::Boolean)}
    def esm?
      module_type === 'ESM'
    end

    sig {returns(T::Boolean)}
    def dts?
      self.module_type === 'DTS'
    end

    sig {returns(T::Boolean)}
    def modern?
      esm? || dts?
    end

    sig { void }
    def require_esm
      raise "ESM module type is required" unless modern?
    end

    sig { returns(String) }
    def source_file
      File.dirname(__FILE__) + "/../" + default_file_name
    end

    sig { returns(Pathname) }
    def output_file
      webpacker_dir = defined?(::Webpacker) ?
        T.unsafe(::Webpacker).config.source_path :
        pathname('app', 'javascript')
      sprockets_dir = pathname('app','assets','javascripts')
      file_name = file || default_file_name
      sprockets_file = sprockets_dir.join(file_name)
      webpacker_file = webpacker_dir.join(file_name)
      !Dir.exist?(webpacker_dir) && defined?(::Sprockets) ? sprockets_file : webpacker_file
    end

    protected

    sig { void }
    def normalize_and_verify
      normalize
      verify
    end

    sig { params(parts: String).returns(Pathname) }
    def pathname(*parts)
      Pathname.new(File.join(*T.unsafe(parts)))
    end

    sig { returns(String) }
    def default_file_name
      dts? ? "routes.d.ts" : "routes.js"
    end

    sig {void}
    def normalize
      self.module_type = module_type&.upcase || 'NIL'
    end

    sig { void }
    def verify
      if module_type != 'NIL' && namespace
        raise "JsRoutes namespace option can only be used if module_type is nil"
      end
    end
  end
end
