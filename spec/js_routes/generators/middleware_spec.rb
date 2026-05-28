require 'spec_helper'

describe JsRoutes::Generators::Middleware do

  it "has correct source_root" do
    expect(JsRoutes::Generators::Middleware.source_root).to eq(gem_root.join('lib/templates').to_s)
  end

end
