require "spec_helper"

describe JsRoutes, "compatibility with CJS" do
  before do
    evaljs("module = { exports: null }")
    evaljs(described_class.generate(
      module_type: "CJS",
      include: /^inboxes/
    ))
  end

  it "defines module exports" do
    expectjs("module.exports.inboxes_path()").to eq(test_routes.inboxes_path)
  end
end
