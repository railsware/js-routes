require "rails/generators"
require 'js_routes/utils'

class JsRoutes::Generators::Webpacker < Rails::Generators::Base

  def create_webpack
    copy_file "initializer.rb", "config/initializers/js_routes.rb"
    copy_file "erb.js", "config/webpack/loaders/erb.js"
    copy_file "routes.js.erb", "#{JsRoutes::Utils.shakapacker.config.source_path}/routes.js.erb"
    inject_into_file "config/webpack/environment.js", loader_content
    if path = application_js_path
      inject_into_file path, pack_content
    end
    command = Rails.root.join("./bin/yarn add rails-erb-loader")
    run command
  end

  protected

  def pack_content
    <<-JS
import * as Routes from 'routes.js.erb';
alert(Routes.root_path())
    JS
  end

  def loader_content
    <<-JS
const erb = require('./loaders/erb')
environment.loaders.append('erb', erb)
    JS
  end
end
