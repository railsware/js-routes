require "js_routes/generators/base"

class JsRoutes::Generators::Middleware < JsRoutes::Generators::Base
  argument :js_routes_file, type: :string, default: nil, optional: true,
    desc: "Output directory or file path relative to Rails root. " \
          "Directory: app/frontend → app/frontend/routes.js. " \
          "Full path: app/frontend/my_routes.js"

  def create_middleware
    copy_file "initializer.rb", "config/initializers/js_routes.rb"
    if js_routes_file
      inject_into_file "config/initializers/js_routes.rb",
        "  c.file = #{js_routes_file.inspect}\n\n",
        after: "JsRoutes.setup do |c|\n"
    end
    inject_into_file "config/environments/development.rb", middleware_content, before: /^end\n\z/
    inject_into_file "Rakefile", rakefile_content
    inject_into_file ".gitignore", gitignore_content
    if path = application_js_path
      inject_into_file path, pack_content
    end
    JsRoutes.generate!(js_routes_file, typed: true)
  end

  protected

  def pack_content
    <<~JS
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
    <<~RB
      # Update js-routes file before javascript build
      task "#{enhanced_task}" => "js:routes"
    RB
  end

  def gitignore_content
    banner = <<~TXT
      
      # Ignore automatically generated js-routes files.
    TXT

    file_option = js_routes_file ? {file: js_routes_file} : {}
    js_path = JsRoutes::Configuration.new(file_option).output_file.to_s
    dts_path = js_path.sub(%r{(\.d)?\.(j|t)s\z}, ".d.ts")

    banner + [js_path, dts_path].map { |path| File.join("/", path) + "\n" }.join
  end
end
