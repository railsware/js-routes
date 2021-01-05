require "spec_helper"

describe JsRoutes, "#serialize" do

  before(:each) do
    evaljs(JsRoutes.generate({module_type: nil}))
  end

  it "should provide this method" do
    expect(evaljs("Routes.serialize({a: 1, b: [2,3], c: {d: 4, e: 5}, f: ''})")).to eq(
      "a=1&b%5B%5D=2&b%5B%5D=3&c%5Bd%5D=4&c%5Be%5D=5&f="
    )
  end

  it "should provide this method" do
    expect(evaljs("Routes.serialize({a: 1, b: [2,3], c: {d: 4, e: 5}, f: ''})")).to eq(
      "a=1&b%5B%5D=2&b%5B%5D=3&c%5Bd%5D=4&c%5Be%5D=5&f="
    )
  end
end
