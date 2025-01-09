# typed: strict
if defined?(::Rails)
  require 'js_routes/engine'
end
require 'js_routes/version'
require "js_routes/configuration"
require "js_routes/instance"
require "js_routes/types"
require 'active_support/core_ext/string/indent'
require "digest/sha2"

module JsRoutes
  extend T::Sig

  #
  # API
  #

  class << self
    include JsRoutes::Types
    extend T::Sig

    sig { params(block: ConfigurationBlock).void }
    def setup(&block)
      configuration.setup(&block)
    end

    sig { returns(JsRoutes::Configuration) }
    def configuration
      @configuration ||= T.let(Configuration.new, T.nilable(JsRoutes::Configuration))
    end

    sig { params(opts: T.untyped).returns(String) }
    def generate(**opts)
      Instance.new(**opts).generate
    end

    sig { params(file_name: FileName, typed: T::Boolean, opts: T.untyped).void }
    def generate!(file_name = configuration.file, typed: false, **opts)
      instance = Instance.new(file: file_name, **opts)
      instance.generate!
      if typed && instance.configuration.modern?
        definitions!(file_name, **opts)
      end
    end

    sig { params(file_name: FileName, opts: T.untyped).void }
    def remove!(file_name = configuration.file, **opts)
      Instance.new(file: file_name, **opts).remove!
    end

    sig { params(opts: T.untyped).returns(String) }
    def definitions(**opts)
      generate(**opts, module_type: 'DTS')
    end

    sig { params(file_name: FileName, opts: T.untyped).void }
    def definitions!(file_name = nil, **opts)
      file_name ||= configuration.file

      file_name = file_name&.sub(%r{(\.d)?\.(j|t)s\Z}, ".d.ts")
      generate!(file_name, **opts, module_type: 'DTS')
    end

    sig { params(value: T.untyped).returns(String) }
    def json(value)
      ActiveSupport::JSON.encode(value)
    end

    sig { returns(String) }
    def digest
      Digest::SHA256.file(
        Rails.root.join("config/routes.rb")
      ).hexdigest
    end
  end
  module Generators
  end
end

require "js_routes/middleware"
require "js_routes/generators/webpacker"
require "js_routes/generators/middleware"
