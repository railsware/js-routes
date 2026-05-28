require "fileutils"
require "spec_helper"

describe JsRoutes, "PKG module type" do
  describe ".package" do
    subject(:generated_package) { JsRoutes.package }

    it "exports __route__ exactly once with an initializer" do
      expect(generated_package.scan(/^export const __route__/).length).to eq(1)
      expect(generated_package).to include("export const __route__ =")
    end

    it "does not contain route definitions" do
      expect(generated_package).not_to include("inboxes_path")
    end

    it "exports utility methods" do
      expect(generated_package).to include("export const configure =")
      expect(generated_package).to include("export const config =")
      expect(generated_package).to include("export const serialize =")
    end

    it "raises an error for non-PKG module type" do
      expect { JsRoutes.package(module_type: "ESM") }.to raise_error(RuntimeError, /PKG/)
    end
  end

  describe ".package!" do
    let(:path) { Rails.root.join("app", "assets", "javascripts", "router.js") }

    after(:each) { JsRoutes.remove! }

    it "writes to router.js by default" do
      JsRoutes.package!
      expect(File.exist?(path)).to be_truthy
    end

    it "writes valid content with __route__ export" do
      JsRoutes.package!
      content = File.read(path)
      expect(content).to include("export const __route__ =")
      expect(content.scan(/^export const __route__/).length).to eq(1)
    end

    it "accepts a custom file name" do
      custom_path = Rails.root.join("app", "assets", "javascripts", "custom_pkg.js")
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

  describe "consumer routes (package: option)" do
    let(:generated_js) do
      JsRoutes.generate(module_type: "ESM", package: "./router.js", include: /\Ainbox/)
    end

    it "imports __route__ from the package" do
      expect(generated_js).to include("import { __route__ } from './router.js';")
    end

    context "with package: true" do
      let(:generated_js) do
        JsRoutes.generate(module_type: "ESM", package: true, include: /\Ainbox/)
      end

      it "uses the default package file path" do
        expect(generated_js).to include("import { __route__ } from './router.js';")
      end
    end

    it "uses __route__ in every route definition" do
      route_lines = generated_js.lines.select { |l| l.include?("export const") && l.include?("_path") }
      expect(route_lines).to all(include("__route__("))
    end

    it "does not embed the full js-routes runtime" do
      expect(generated_js).not_to include("UtilsClass")
    end

    it "raises when package: is used without ESM module type" do
      expect {
        JsRoutes.generate(module_type: "UMD", package: "./router.js")
      }.to raise_error(RuntimeError, /ESM/)
    end
  end
end
