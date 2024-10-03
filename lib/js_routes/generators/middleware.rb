require "js_routes/generators/base"

class JsRoutes::Generators::Middleware < JsRoutes::Generators::Base

  def create_middleware
    copy_file "initializer.rb", "config/initializers/js_routes.rb"
    inject_into_file "config/environments/development.rb", middleware_content, before: /^end\n\z/
    inject_into_file "Rakefile", rakefile_content
    inject_into_file ".gitignore", gitignore_content
    if path = application_js_path
      inject_into_file path, pack_content
    end
    JsRoutes.generate!
    JsRoutes.definitions! if JsRoutes.configuration.modern?
  end

  protected

  def pack_content
    <<-JS
import {root_path} from '../routes';
alert(`JsRoutes installed.\\nYour root path is ${root_path()}`)
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
    enhanced_task = depends_on_js_bundling? ? "javascript:build" : "assets:precompile"
    dependency_task = JsRoutes.configuration.modern? ? "js:routes:typescript" : 'js:routes'
    <<-RB
# Update js-routes file before javascript build
task "#{enhanced_task}" => "#{dependency_task}"
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
