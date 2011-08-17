module JsRoutes
  class << self


    def generate(options = {})
      js = File.read(File.dirname(__FILE__) + "/routes.js")
      options[:namespace] ||= "Routes"
      js.gsub!("NAMESPACE", options[:namespace])
      js.gsub!("DEFAULT_FORMAT", options[:default_format].to_s)
      js.gsub!("ROUTES", js_routes(options))
    end

    def generate!(options = {})
      file = options[:file] || default_file
      File.open(file, 'w') do |f|
        f.write generate(options)
      end
    end

    #
    # Implementation
    #

    protected
    def js_routes(options = {})

      options[:default_format] ||= ""
      exclude = Array(options[:exclude])

      Rails.application.reload_routes!
      js_routes = Rails.application.routes.named_routes.routes.map do |_, route|
        if exclude.find {|e| route.name =~ e}
          nil
        else
          build_js(route, options)
        end
      end.compact
      
      "{\n" + js_routes.join(",\n") + "}\n"
    end

    def build_js(route, options)
      _ = <<-JS.strip!
  // #{route.name} => #{route.path}
  #{route.name}_path: function(#{build_params route}) {
  return Utils.build_path(#{path_parts(route).inspect}, arguments)
  }
JS
    end


    def build_params route
      route.conditions[:path_info].named_captures.map do |cap|
        name = cap.first
        if !(name.to_s == "format")
          "_" + name.to_s.gsub(/^:/, '')
        end
      end.compact.<<("options").join(', ')
    end


    def path_parts route
      route.path.gsub(/\(\.:format\)$/, "").split(/:[a-z\-_]+/)
    end


    def default_file
      if Rails.version >= "3.1"
        "#{Rails.root}/app/assets/javascripts/routes.js"
      else
        "#{Rails.root}/public/javascripts/routes.js"
      end
    end

  end
end
