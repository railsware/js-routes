module JsRoutes
  class << self


    def generate(options = {})
      js = File.read(File.dirname(__FILE__) + "/routes.js")
      js.gsub!("IDENTITY", js_routes(options))
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

      Rails.application.routes.named_routes.routes.map do |name, route|
        <<-JS
  // #{route.name} => #{route.path}
  #{name.to_s}_path: function(#{build_params route}) {
    var options = Routes.extract_options(arguments);
    var format = options.format || '#{options[:default_format]}';
    delete options.format;
  #{build_default_params route};
    return Routes.check_path('#{build_path route}' + format) + Routes.serialize(options);
  },
JS
      end.join("\n")
    end


    def build_params route
      route.conditions[:path_info].captures.map do |cap|
        if cap.is_a?(Rack::Mount::GeneratableRegexp::DynamicSegment)
          if cap.name.to_s == "format"
            nil
          else
            cap.name.to_s.gsub(':', '')
          end
        end
      end.compact.join(', ')
    end

    def build_default_params route
      route.conditions[:path_info].captures.map do |cap|
        if cap.is_a?(Rack::Mount::GeneratableRegexp::DynamicSegment)
          segg = cap.name.to_s.gsub(':', '')
          "#{segg} = Routes.check_parameter(#{segg});"
        end
      end.join("\n")
    end

    def build_path route
      s = route.path.gsub(/\(\.:format\)$/, ".")

      route.conditions[:path_info].captures.each do |cap|
        unless cap.name.to_s == "format"
          if route.conditions[:path_info].required_params.include?(cap.name)
            s.gsub!(/:#{cap.name.to_s}/){ "' + #{cap.name.to_s.gsub(':','')} + '" }
          else
            s.gsub!(/\((\.)?:#{cap.name.to_s}\)/){ "#{$1}' + #{cap.name.to_s.gsub(':','')} + '" }
          end
        end
      end
      s

    end
    def default_file
      #TODO: better defaults
      "#{Rails.root}/app/assets/javascripts/less_routes.js"
    end

  end
end
