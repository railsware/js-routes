require "spec_helper"

describe JsRoutes, "compatibility with CommonJS (node)"  do
  before(:each) do
    evaljs("module = { exports: null }")
    evaljs(JsRoutes.generate({}))
  end

  it "should define module exports" do
    expect(evaljs("module.exports.inboxes_path()")).to eq(test_routes.inboxes_path())
  end
end
