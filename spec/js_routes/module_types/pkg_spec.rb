require "fileutils"
require "spec_helper"

describe JsRoutes, "PKG module type" do
  describe ".package" do
    subject(:generated_package) { JsRoutes.package }

    it "exports Router as the default export" do
      expect(generated_package).to include("export default Router;")
    end

    it "does not contain route definitions" do
      expect(generated_package).not_to include("inboxes_path")
    end

    it "does not export utility methods individually" do
      expect(generated_package).not_to include("export const configure =")
      expect(generated_package).not_to include("export const __route__ =")
      expect(generated_package).not_to include("export const config =")
      expect(generated_package).not_to include("export const serialize =")
    end

    it "raises an error for non-PKG module type" do
      expect { JsRoutes.package(module_type: "ESM") }.to raise_error(RuntimeError, /PKG/)
    end
  end

  describe ".package!" do
    let(:path) { Rails.root.join(JsRoutes::Configuration.new(module_type: "PKG").output_file) }

    before(:each) { FileUtils.mkdir_p(path.dirname) }
    after(:each) { JsRoutes.remove! }

    it "writes to router.js by default" do
      JsRoutes.package!
      expect(File.exist?(path)).to be_truthy
    end

    it "writes valid content with Router default export" do
      JsRoutes.package!
      content = File.read(path)
      expect(content).to include("export default Router;")
    end

    it "accepts a custom file name" do
      custom_path = path.dirname.join("custom_pkg.js")
      JsRoutes.package!("custom_pkg.js")
      expect(File.exist?(custom_path)).to be_truthy
      FileUtils.rm_f(custom_path)
    end

    it "does not overwrite unchanged file" do
      JsRoutes.package!
      mtime = File.mtime(path)
      sleep(0.01)
      JsRoutes.package!
      expect(File.mtime(path)).to eq(mtime)
    end

    it "raises an error for non-PKG module type" do
      expect { JsRoutes.package!(module_type: "ESM") }.to raise_error(RuntimeError, /PKG/)
    end
  end

  describe "combined package + consumer routes (functional)" do
    let(:package_js) { JsRoutes.package }
    let(:consumer_js) do
      JsRoutes.generate(module_type: "ESM", package: "./router.js", include: /\Ainbox/)
    end

    before do
      # Simulate ESM by stripping export/import keywords so MiniRacer can eval both together
      combined = package_js
        .gsub(/^export default \w+;\n?/, "")
        .gsub("export const ", "const ") +
        consumer_js
          .gsub(/^import \S+ from '[^']+';(\n)?/, "")
          .gsub("export const ", "const ")
      evaljs(combined, force: true)
    end

    it "route helpers produce correct paths" do
      expectjs("inboxes_path()").to eq(test_routes.inboxes_path())
    end

    it "route helpers with arguments produce correct paths" do
      expectjs("inbox_path(1)").to eq(test_routes.inbox_path(1))
    end
  end

  describe "consumer routes (package: option)" do
    let(:generated_js) do
      JsRoutes.generate(module_type: "ESM", package: "./router.js", include: /\Ainbox/)
    end

    it "imports Router from the package" do
      expect(generated_js).to include("import Router from './router.js';")
    end

    context "with package: true" do
      let(:generated_js) do
        JsRoutes.generate(module_type: "ESM", package: true, include: /\Ainbox/)
      end

      it "uses the default package file path" do
        expect(generated_js).to include("import Router from './router.js';")
      end
    end

    it "uses __route__ in every route definition" do
      route_lines = generated_js.lines.select { |l| l.include?("export const") && l.include?("_path") }
      expect(route_lines).to all(include("__route__("))
    end

    it "does not embed the full js-routes runtime" do
      expect(generated_js).not_to include("UtilsClass")
    end

    it "does not re-export utility methods" do
      expect(generated_js).to include("export const configure")
      expect(generated_js).to include("export const config")
      expect(generated_js).to include("export const serialize")
    end

    it "raises when package: is used without ESM module type" do
      expect {
        JsRoutes.generate(module_type: "UMD", package: true)
      }.to raise_error(RuntimeError, /ESM/)
    end
  end
end
