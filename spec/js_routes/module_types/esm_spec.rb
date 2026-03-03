require "active_support/core_ext/string/strip"
require "spec_helper"

describe JsRoutes, "compatibility with ESM"  do
  let(:generated_js) {
    JsRoutes.generate(module_type: 'ESM', include: /\Ainbox/)
  }

  before(:each) do
    # export keyword is not supported by a simulated js environment
    evaljs(generated_js.gsub("export const ", "const "))
  end

  it "defines route helpers" do
    expectjs("inboxes_path()").to eq(test_routes.inboxes_path())
  end

  it "exports route helpers" do
    expect(generated_js).to include(<<-DOC.rstrip)
/**
 * Generates rails route to
 * /inboxes(.:format)
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inboxes_path = /*#__PURE__*/ __jsr.r(
DOC
  end

  it "exports utility methods" do
    expect(generated_js).to include("export const serialize = ")
  end

  it "defines utility methods" do
    expectjs("serialize({a: 1, b: 2})").to eq({a: 1, b: 2}.to_param)
  end

  describe "compiled javascript asset" do
    subject { ERB.new(File.read("app/assets/javascripts/js-routes.js.erb")).result(binding) }
    it "should have js routes code" do
      is_expected.to include("export const inbox_message_path = /*#__PURE__*/ __jsr.r(")
    end
  end
end

describe JsRoutes, "compatibility with ESM using the package argument" do
  describe '.generate_package' do
    let(:generated_package) {
      JsRoutes.generate_package(module_type: 'ESM')
    }

    it 'generates package with __jsr export' do
      expect(generated_package).to include("export { __jsr };")
    end
  end

  describe '.generate' do
    let(:generated_js) {
      JsRoutes.generate(module_type: 'ESM', package: './routes_core.js', include: /\Ainbox/)
    }

    it "imports __jsr from package" do
      expect(generated_js).to include("import { __jsr } from './routes_core.js';")
    end
  end

  describe '.generate_package!' do
    let(:path) { Rails.root.join('app', 'assets', 'javascripts', 'routes_core.js') }
    let(:generated_package) {
      JsRoutes.generate_package!(module_type: 'ESM')

      File.read(path)
    }

    after(:each) do
      JsRoutes.remove!
    end

    it "should generate package file" do
      expect(generated_package).to include("export { __jsr };")
    end
  end
end
