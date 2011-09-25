require "js_routes"
class JsRoutes
  if defined?(Rails) && Rails.version >= "3.1"
    class Engine < Rails::Engine

      JS_ROUTES_ASSET = 'js-routes'

      config.after_initialize do
        routes = Rails.root.join('config','routes.rb')
        Rails.application.assets.register_preprocessor 'application/javascript', :routes_dependent do |ctx,data|
          ctx.depend_on(routes) if ctx.logical_path == JS_ROUTES_ASSET
          data
        end
      end
    end
  end
end
