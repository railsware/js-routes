require "spec_helper"

describe JsRoutes, "compatibility with AMD/require.js"  do

  before(:each) do
    evaljs("window.GlobalCheck = {};")
    evaljs("window.define = function (requirs, callback) { window.GlobalCheck['js-routes'] = callback.call(this); return window.GlobalCheck['js-routes']; };")
    evaljs("window.define.amd = { jQuery: true };")
    evaljs("window.require = function (r, c) { return c.apply(null, [window.GlobalCheck[r[0]]]); };")
    evaljs(JsRoutes.generate({}))
  end

  it "should working from global scope" do
    expect(evaljs("Routes.inboxes_path()")).to eq(routes.inboxes_path())
  end

  it "should working from define function" do
    expect(evaljs("Routes.inboxes_path()")).to eq(evaljs("GlobalCheck['js-routes'].inboxes_path()"))
  end

  it "should working from require" do
    expect(evaljs("require(['js-routes'], function(r){ return r.inboxes_path(); })")).to eq(routes.inboxes_path())
  end

end
