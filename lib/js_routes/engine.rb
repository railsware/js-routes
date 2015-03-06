class JsRoutes
  class Engine < ::Rails::Engine
    JS_ROUTES_ASSET = 'js-routes'

    initializer 'js-routes.dependent_on_routes', after: "sprockets.environment" do
      if Rails.application.assets.respond_to?(:register_preprocessor)
        route_paths = Rails.application.paths["config/routes#{3 == Rails::VERSION::MAJOR ? '' : '.rb'}"].to_a

        route_paths.each do |path|
          Rails.application.assets.register_preprocessor 'application/javascript', :'js-routes_dependent_on_routes' do |ctx,data|
            ctx.depend_on(Pathname.new(path)) if ctx.logical_path == JS_ROUTES_ASSET
            data
          end
        end
      end
    end
  end
end
