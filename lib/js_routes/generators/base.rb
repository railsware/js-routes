
require "rails/generators"

class JsRoutes::Generators::Base < Rails::Generators::Base

  source_root File.expand_path(__FILE__ + "/../../../templates")

  protected

  def application_js_path
    [
      "app/javascript/packs/application.js",
      "app/javascript/controllers/application.js",
    ].find do |path|
      File.exist?(Rails.root.join(path))
    end
  end

  def depends_on?(gem_name)
    !!Bundler.load.gems.find {|g| g.name == gem_name}
  end

  def depends_on_js_bundling?
    depends_on?('jsbundling-rails')
  end

  def depends_on_webpacker?
    depends_on?('webpacker')
  end
end
