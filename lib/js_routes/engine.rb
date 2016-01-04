class JsRoutes
  class Engine < ::Rails::Engine
    config.after_initialize do
      class ::Sprockets::DirectiveProcessor
        def process_jsroutes_depend_on_routes_directive
          routes_path = Rails.root.join('config', 'routes.rb').to_s
          process_depend_on_directive "file://#{routes_path}"
        end
      end
    end
  end
end
