# typed: strict
require "js_routes/types"

module JsRoutes
  # A Rack middleware that automatically updates routes file
  # whenever routes.rb is modified
  #
  # Inspired by
  # https://github.com/fnando/i18n-js/blob/main/lib/i18n/js/middleware.rb
  class Middleware
    include JsRoutes::Types
    extend T::Sig

    sig { params(app: T.proc.params(a0: StringHash).returns(UntypedArray)).void }
    def initialize(app)
      @app = app
      @routes_file = T.let(Rails.root.join("config/routes.rb"), Pathname)
      @mtime = T.let(nil, T.nilable(Time))
    end

    sig { params(env: StringHash).returns(UntypedArray) }
    def call(env)
      update_js_routes
      @app.call(env)
    end

    protected

    sig { void }
    def update_js_routes
      new_mtime = routes_mtime
      unless new_mtime == @mtime
        regenerate
        @mtime = new_mtime
      end
    end

    sig { void }
    def regenerate
      JsRoutes.generate!
      JsRoutes.definitions!
    end

    sig { returns(T.nilable(Time)) }
    def routes_mtime
      File.mtime(@routes_file)
    rescue Errno::ENOENT
      nil
    end
  end
end
