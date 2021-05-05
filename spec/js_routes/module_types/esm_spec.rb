require "spec_helper"

describe JsRoutes, "compatibility with ESM"  do

  let(:generated_js) {
    JsRoutes.generate(module_type: 'ESM')
  }

  before(:each) do
    # export keyword is not supported by a simulated js environment
    evaljs(generated_js.gsub("export const ", "const "))
  end

  it "defines route helpers" do
    expect(evaljs("inboxes_path()")).to eq(test_routes.inboxes_path())
  end

  it "exports route helpers" do
    expect(generated_js).to include(<<-EOI.strip_heredoc.strip)
    // inboxes => /inboxes(.:format)
    // function(options)
    export const inboxes_path = __jsr.r(
    EOI
  end

  it "exports utility methods" do
    expect(generated_js).to include("export const serialize = ")
  end

  it "defines utility methods" do
    expect(evaljs("serialize({a: 1, b: 2})")).to eq({a: 1, b: 2}.to_param)
  end
end
