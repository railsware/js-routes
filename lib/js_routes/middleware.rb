# typed: strict
require "js_routes/types"

module JsRoutes
  # A Rack middleware that automatically updates routes file
  # whenever routes.rb is modified
  #
  # Inspired by
  # https://github.com/fnando/i18n-js/blob/v3/lib/i18n/js/middleware.rb
  class Middleware
    include JsRoutes::Types
    include RackApp

    extend T::Sig

    sig { params(app: T.untyped).void }
    def initialize(app)
      @app = app
      @digest = T.let(nil, T.nilable(String))
    end

    sig { override.params(env: StringHash).returns(UntypedArray) }
    def call(env)
      update_js_routes
      @app.call(env)
    end

    protected

    sig { void }
    def update_js_routes
      new_digest = fetch_digest
      unless new_digest == @digest
        regenerate
        @digest = new_digest
      end
    end

    sig { void }
    def regenerate
      JsRoutes.generate!(typed: true)
    end

    sig { returns(T.nilable(String)) }
    def fetch_digest
      JsRoutes.digest
    rescue Errno::ENOENT
      nil
    end
  end
end
