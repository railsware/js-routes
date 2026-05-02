
require "rails/generators"

class JsRoutes::Generators::Base < Rails::Generators::Base

  def self.inherited(subclass)
    super
    subclass.source_root(File.expand_path(__FILE__ + "/../../../templates"))
  end

  protected

  def application_js_path
    js_dir = JsRoutes::Configuration.rails_javascript_path
    [
      "app/#{js_dir}/packs/application.ts",
      "app/#{js_dir}/packs/application.js",
      "app/#{js_dir}/controllers/application.ts",
      "app/#{js_dir}/controllers/application.js",
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
