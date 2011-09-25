require "js_routes"
module JsRoutes
  if defined?(Rails)
    class Engine < Rails::Engine; end
  end
end
