# we need to run post_rails_init_spec as the latest
# because it cause unrevertable changes to runtime
# what is why I added "zzz_last" in the beginning

require "sprockets"
require "sprockets/railtie"
require "spec_helper"
require "fileutils"

ROUTES_JS_NAME = Rails.root.join("app", "assets", "javascripts", "routes.js").to_s
CONFIG_ROUTES_PATH = Rails.root.join("config", "routes.rb").to_s

describe "after Rails initialization", :slow do
  def sprockets_v3?
    Sprockets::VERSION.to_i >= 3
  end

  def sprockets_v4?
    Sprockets::VERSION.to_i >= 4
  end

  def sprockets_context(environment, name, filename)
    if sprockets_v3?
      Sprockets::Context.new(environment: environment, name: name, filename: filename.to_s, metadata: {})
    else
      Sprockets::Context.new(environment, name, filename)
    end
  end

  def evaluate(ctx, file)
    if sprockets_v3?
      ctx.load(ctx.environment.find_asset(file, pipeline: :default).uri).to_s
    else
      ctx.evaluate(file)
    end
  end

  before do
    FileUtils.mkdir_p(Rails.root.join("tmp"))
    FileUtils.rm_rf Rails.root.join("tmp/cache")
    JsRoutes.remove!(ROUTES_JS_NAME)
    JsRoutes.generate!(ROUTES_JS_NAME)
  end

  before(:all) do
    JsRoutes::Engine.install_sprockets!
    Rails.configuration.eager_load = false
    Rails.application.initialize!
  end

  it "generates routes file" do
    expect(File).to exist(ROUTES_JS_NAME)
  end

  it "does not rewrite routes file if nothing changed" do
    routes_file_mtime = File.mtime(ROUTES_JS_NAME)
    JsRoutes.generate!(ROUTES_JS_NAME)
    expect(File.mtime(ROUTES_JS_NAME)).to eq(routes_file_mtime)
  end

  it "rewrites routes file if file content changed" do
    # Change content of existed routes file (add space to the end of file).
    File.open(ROUTES_JS_NAME, "a") { |f| f << " " }
    routes_file_mtime = File.mtime(ROUTES_JS_NAME)
    sleep(0.1)
    JsRoutes.generate!(ROUTES_JS_NAME)
    expect(File.mtime(ROUTES_JS_NAME)).not_to eq(routes_file_mtime)
  end

  describe JsRoutes::Middleware do
    def file_content
      File.read(ROUTES_JS_NAME)
    end

    it "works" do
      JsRoutes.remove!

      real_digest = JsRoutes.digest
      stub_digest = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

      expect(File.exist?(ROUTES_JS_NAME)).to be(false)
      app = lambda do |env|
        [200, {}, ""]
      end
      middleware = described_class.new(app)
      middleware.call({})

      expect(File.exist?(ROUTES_JS_NAME)).to be(true)
      expect(file_content).to include(real_digest)
      JsRoutes.remove!
      middleware.call({})
      expect(File.exist?(ROUTES_JS_NAME)).to be(false)

      allow(JsRoutes).to receive(:digest).and_return(stub_digest)
      middleware.call({})

      expect(File.exist?(ROUTES_JS_NAME)).to be(true)
      expect(file_content).to include(stub_digest)
    end
  end

  describe ".generate!" do
    let(:dir) { Rails.root.join("tmp") }

    it "works" do
      file = dir.join("typed_routes.js")
      JsRoutes.remove!(file)
      expect(File.exist?(file)).to be(false)
      expect(File.exist?(dir.join("typed_routes.d.ts"))).to be(false)
      JsRoutes.generate!(file, module_type: "ESM", typed: true)
      expect(File.exist?(file)).to be(true)
      expect(File.exist?(dir.join("typed_routes.d.ts"))).to be(true)
    end

    it "skips definitions if module is not ESM" do
      file = dir.join("typed_routes.js")
      definitions = dir.join("typed_routes.d.ts")
      JsRoutes.remove!(file)
      expect(File.exist?(file)).to be(false)
      expect(File.exist?(definitions)).to be(false)
      JsRoutes.generate!(file, module_type: nil, typed: true)
      expect(File.exist?(file)).to be(true)
      expect(File.exist?(definitions)).to be(false)
    end
  end

  context "JsRoutes::Engine" do
    def test_asset_path
      Rails.root.join("app", "assets", "javascripts", "test.js")
    end

    before(:all) do
      File.open(Rails.root.join("app", "assets", "javascripts", "test.js"), "w") do |f|
        f.puts "function() {}"
      end
    end

    after(:all) do
      FileUtils.rm_f(Rails.root.join("app", "assets", "javascripts", "test.js"))
    end

    context "the preprocessor" do
      before do
        if sprockets_v3? || sprockets_v4?
          expect_any_instance_of(Sprockets::Context).to receive(:depend_on)
        else
          expect(ctx).to receive(:depend_on).with(CONFIG_ROUTES_PATH.to_s)
        end
      end

      let!(:ctx) do
        sprockets_context(Rails.application.assets,
          "js-routes.js",
          Pathname.new("js-routes.js"))
      end

      context "when dealing with js-routes.js" do
        context "with Rails" do
          context "and initialize on precompile" do
            before do
              Rails.application.config.assets.initialize_on_precompile = true
            end

            it "renders some javascript" do
              expect(evaluate(ctx, "js-routes.js")).to match(/Modules\.define_module/)
            end
          end

          context "and not initialize on precompile" do
            before do
              Rails.application.config.assets.initialize_on_precompile = false
            end

            it "raises an exception if 3 version" do
              expect(evaluate(ctx, "js-routes.js")).to match(/Modules\.define_module/)
            end
          end
        end
      end
    end

    context "when not dealing with js-routes.js" do
      it "does not depend on routes.rb" do
        ctx = sprockets_context(Rails.application.assets,
          "test.js",
          test_asset_path)
        expect(ctx).not_to receive(:depend_on)
        evaluate(ctx, "test.js")
      end
    end
  end
end

describe "JSRoutes thread safety", :slow do
  before do
    Rails.application.initialize!
  rescue
  end

  it "can produce the routes from multiple threads" do
    threads = Array.new(2) do
      Thread.start do
        10.times {
          expect { JsRoutes.generate }.not_to raise_error
        }
      end
    end

    threads.each do |thread|
      thread.join
    end
  end
end
