require 'spec_helper'

describe JsRoutes::Generators::Middleware do

  it "has correct source_root" do
    expect(JsRoutes::Generators::Middleware.source_root).to eq(gem_root.join('lib/templates').to_s)
  end

  it "sets the undefined query parameter migration option in the generated initializer" do
    expect(File.read(gem_root.join('lib/templates/initializer.rb'))).to include(
      "c.omit_undefined_query_parameters = true"
    )
  end
end
