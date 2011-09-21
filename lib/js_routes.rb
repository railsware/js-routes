module JsRoutes
  class Options < Struct.new(:file, :namespace, :default_format, :exclude, :include); end

  class << self
    def setup
      options.tap { |opts| yield(opts) if block_given? }
    end

    def options
      @options ||= Options.new
    end

    def generate(options = nil)
      options ||= self.options
      namespace = options[:namespace] || "Routes"
      default_format = options[:default_format] || ''
      prefix = options[:prefix] || ''

      js = File.read(File.dirname(__FILE__) + "/routes.js")
      js.gsub!("NAMESPACE", namespace)
      js.gsub!("DEFAULT_FORMAT", default_format)
      js.gsub!("PREFIX", prefix)
      js.gsub!("ROUTES", js_routes(options))
    end

    def generate!(options = nil)
      # Some libraries like devise do yet load their routes so we will wait
      # until initialization process finish
      # https://github.com/railsware/js-routes/issues/7
      Rails.configuration.after_initialize do
        options ||= self.options
        file = options[:file] || default_file
        File.open(file, 'w') do |f|
          f.write generate(options)
        end
      end
    end

    #
    # Implementation
    #

    protected
    def js_routes(options = {})
      excludes = options[:exclude] || []
      includes = options[:include] || //

      Rails.application.reload_routes!
      js_routes = Rails.application.routes.named_routes.routes.map do |_, route|
        if any_match?(route, excludes) || !any_match?(route, includes)
          nil
        else
          build_js(route)
        end
      end.compact
      
      "{\n" + js_routes.join(",\n") + "}\n"
    end

    def any_match?(route, matchers)
      matchers = Array(matchers)
      matchers.any? {|regex| route.name =~ regex}
    end

    def build_js(route)
      params = build_params(route)
      _ = <<-JS.strip!
  // #{route.name} => #{route.path}
  #{route.name}_path: function(#{params.<<("options").join(", ")}) {
  return Utils.build_path(#{params.size - 1}, #{path_parts(route).inspect}, #{optional_params(route).inspect}, arguments)
  }
  JS
    end

    def optional_params(route)
      optional_named_captures_regexp = /\?\:.+?\(\?\<(.+?)\>/
      path_info = route.conditions[:path_info]
      path_info.source.scan(optional_named_captures_regexp).flatten
    end

    def build_params(route)
      optional_named_captures = optional_params(route)
      route.conditions[:path_info].named_captures.to_a.sort do |cap1, cap2|
        # Hash is not ordered in Ruby 1.8.7
        cap1.last.first <=> cap2.last.first
      end.map do |cap|
        name = cap.first
        if !(optional_named_captures.include?(name.to_s))
          # prepending each parameter name with underscore
          # to prevent conflict with JS reserved words
          "_" + name.to_s.gsub(/^:/, '')
        end
      end.compact
    end

    def path_parts(route)
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
