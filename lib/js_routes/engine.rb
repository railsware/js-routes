require 'sprockets/version'

class JsRoutes
  SPROCKETS3 = Gem::Version.new(Sprockets::VERSION) >= Gem::Version.new('3.0.0')
  class Engine < ::Rails::Engine

    config.after_initialize do
      routes = Rails.root.join('config', 'routes.rb').to_s

      if Rails.application.assets.respond_to?(:register_preprocessor)
        Rails.application.assets.register_preprocessor 'application/javascript', :'js-routes_dependent_on_routes' do |ctx,data|
          ctx.depend_on(routes) if ctx.logical_path == 'js-routes'
          data
        end
      end
    end unless SPROCKETS3
  end
end
