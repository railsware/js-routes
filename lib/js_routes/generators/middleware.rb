require "rails/generators"

class JsRoutes::Generators::Middleware < Rails::Generators::Base

  source_root File.expand_path(__FILE__ + "/../../../templates")

  def create_middleware
    copy_file "initializer.rb", "config/initializers/js_routes.rb"
    # copy_file "erb.js", "config/webpack/loaders/erb.js"
    # copy_file "routes.js.erb", "app/javascript/routes.js.erb"
    # inject_into_file "config/webpack/environment.js", loader_content
    inject_into_file "app/javascript/packs/application.js", pack_content
    inject_into_file "config/environments/development.rb", middleware_content, before: /^end\n\z/
  end

  protected

  def pack_content
    <<-JS
import * as Routes from '../routes';
window.Routes = Routes;
    JS
  end

  def middleware_content
    <<-RB

  # Automatically update routes.js file
  # when routes.rb is changed
  config.middleware.use(JsRoutes::Middleware)
    RB
  end
end
