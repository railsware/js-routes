require "rails/generators"

class JsRoutes::Generators::Middleware < Rails::Generators::Base

  source_root File.expand_path(__FILE__ + "/../../../templates")

  def create_middleware
    copy_file "initializer.rb", "config/initializers/js_routes.rb"
    inject_into_file "app/javascript/packs/application.js", pack_content
    inject_into_file "config/environments/development.rb", middleware_content, before: /^end\n\z/
    inject_into_file "Rakefile", rakefile_content
    inject_into_file ".gitignore", gitignore_content
    JsRoutes.generate!
    JsRoutes.definitions!
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

  # Automatically update js-routes file
  # when routes.rb is changed
  config.middleware.use(JsRoutes::Middleware)
    RB
  end

  def rakefile_content
    <<-RB

# Update js-routes file before assets precompile
namespace :assets do
  task :precompile => "js:routes:typescript"
end
    RB
  end

  def gitignore_content
    banner = <<-TXT

# Ignore automatically generated js-routes files.
    TXT

    banner + [
      {},
      {module_type: 'DTS'}
    ].map do |config|
      File.join('/', JsRoutes::Configuration.new(config).output_file) + "\n"
    end.join
  end
end
