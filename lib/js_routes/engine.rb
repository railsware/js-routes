class JsRoutesSprocketsExtension
  def initialize(filename, &block)
    @filename = filename
    @source   = block.call
  end

  def render(context, empty_hash_wtf)
    self.class.run(@filename, @source, context)
  end

  def self.run(filename, source, context)
    routes = Rails.root.join('config', 'routes.rb').to_s
    context.depend_on(routes) if context.logical_path == 'js-routes'
    source
  end

  def self.call(input)
    filename = input[:filename]
    source   = input[:data]
    context  = input[:environment].context_class.new(input)

    result = run(filename, source, context)
    { data: result }
  end
end

class Engine < ::Rails::Engine
  initializer 'js-routes.dependent_on_routes', after: :engines_blank_point, before: :finisher_hook do
    Rails.application.config.assets.register_preprocessor 'application/javascript', JsRoutesSprocketsExtension
  end
end