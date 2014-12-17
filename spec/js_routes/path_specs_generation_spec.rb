require 'spec_helper'

def path_specs
  draw_routes
  routes = []
  App.routes.named_routes.routes.each do |_, route|
    if route.app.respond_to?(:superclass) && route.app.superclass == Rails::Engine && !route.path.anchored
      route.app.routes.named_routes.routes.each do |_, engine_route|
        parent_spec = route.try(:path).try(:spec)
        name = [route.try(:name), engine_route.name].compact.join('_')
        routes << [name, "#{parent_spec}#{engine_route.path.spec}"]
      end
    else
      routes << [route.name, route.path.spec.to_s]
    end
  end
  Hash[routes]
end

describe JsRoutes, 'path specs generation' do

  before(:each) do
    evaljs(JsRoutes.generate({}))
  end

  path_specs.each do |route, spec|
    it "should create a spec function on the #{route}_path helper" do
      expect(evaljs("typeof Routes.#{route}_path.spec").downcase).to eq('function')
    end

    it "should generate the correct spec for #{route}_path" do
      expect(evaljs("Routes.#{route}_path.spec()")).to eq(spec)
    end
  end
end
