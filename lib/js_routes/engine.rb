if defined?(Rails) && Rails.version >= "3.1"
  class JsRoutes
    class Engine < Rails::Engine
      JS_ROUTES_ASSET = 'js-routes'

      initializer 'js-routes.dependent_on_routes', :after => "sprockets.environment" do
        routes = Rails.root.join('config','routes.rb')
        Rails.application.assets.register_preprocessor 'application/javascript', :'js-routes_dependent_on_routes' do |ctx,data|
          ctx.depend_on(routes) if ctx.logical_path == JS_ROUTES_ASSET
          data
        end
      end

      initializer 'js-routes.setup', :group => :all do |app|
        # load up the js-routes configuration file (should one exist)
        config_file = Rails.root.join('config','js-routes.rb')
        JsRoutes.instance_eval(IO.read(config_file)) if File.exist?(config_file)
      end
    end
  end
end
