class JsRoutesSprocketsExtension
  def initialize(filename, &block)
    @filename = filename
    @source   = block.call
  end

  def render(context, empty_hash_wtf)
    self.class.run(@filename, @source, context)
  end

  def self.run(filename, source, context)
    if context.logical_path == 'js-routes'
      routes = Rails.root.join('config', 'routes.rb').to_s
      context.depend_on(routes)
    end
    source
  end

  def self.call(input)
    filename = input[:filename]
    source   = input[:data]
    context  = input[:environment].context_class.new(input)

    result = run(filename, source, context)
    context.metadata.merge(data: result)
  end
end


class Engine < ::Rails::Engine
  sprockets3       = Gem::Version.new(Sprockets::VERSION) >= Gem::Version.new('3.0.0')
  initializer_args = if sprockets3
                       { after: :engines_blank_point, before: :finisher_hook }
                     else
                       { after: "sprockets.environment" }
                     end

  initializer 'js-routes.dependent_on_routes', initializer_args do
    Sprockets.register_preprocessor 'application/javascript', JsRoutesSprocketsExtension
  end
end