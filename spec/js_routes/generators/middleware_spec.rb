require "spec_helper"

describe JsRoutes::Generators::Middleware do
  it "has correct source_root" do
    expect(JsRoutes::Generators::Middleware.source_root).to eq(gem_root.join("lib/templates").to_s)
  end

  describe "#gitignore_content" do
    subject(:generator) { described_class.new([js_routes_file].compact) }

    context "without custom file" do
      let(:js_routes_file) { nil }

      it "uses the default JS path" do
        default_path = JsRoutes::Configuration.new.output_file.to_s
        expect(generator.send(:gitignore_content)).to include("/#{default_path}")
      end

      it "includes the default DTS path" do
        default_path = JsRoutes::Configuration.new.output_file.to_s.sub(/\.js\z/, ".d.ts")
        expect(generator.send(:gitignore_content)).to include("/#{default_path}")
      end
    end

    context "with a custom file path" do
      let(:js_routes_file) { "app/frontend/routes.js" }

      it "uses the custom JS path" do
        expect(generator.send(:gitignore_content)).to include("/app/frontend/routes.js")
      end

      it "derives the DTS path from the custom JS path" do
        expect(generator.send(:gitignore_content)).to include("/app/frontend/routes.d.ts")
      end

      it "does not include the default JS path" do
        expect(generator.send(:gitignore_content)).not_to include("/app/javascript/routes.js")
      end
    end

    context "with a directory path" do
      let(:js_routes_file) { "app/frontend" }

      it "appends routes.js to the directory" do
        expect(generator.send(:gitignore_content)).to include("/app/frontend/routes.js")
      end

      it "appends routes.d.ts to the directory" do
        expect(generator.send(:gitignore_content)).to include("/app/frontend/routes.d.ts")
      end
    end
  end

  describe "output_file with custom path" do
    it "uses the path as-is when it contains a directory component" do
      config = JsRoutes::Configuration.new(file: "app/frontend/routes.js")
      expect(config.output_file.to_s).to eq("app/frontend/routes.js")
    end

    it "appends routes.js when given a directory" do
      config = JsRoutes::Configuration.new(file: "app/frontend")
      expect(config.output_file.to_s).to eq("app/frontend/routes.js")
    end

    it "appends routes.d.ts when given a directory in DTS mode" do
      config = JsRoutes::Configuration.new(file: "app/frontend", module_type: "DTS")
      expect(config.output_file.to_s).to eq("app/frontend/routes.d.ts")
    end

    it "prepends JS directory for bare filenames" do
      config = JsRoutes::Configuration.new(file: "custom_routes.js")
      expect(config.output_file.to_s).to include("custom_routes.js")
      expect(config.output_file.to_s).not_to eq("custom_routes.js")
    end

    it "uses default path when file option is nil" do
      config = JsRoutes::Configuration.new
      expect(config.output_file.to_s).to include("routes.js")
    end
  end
end
