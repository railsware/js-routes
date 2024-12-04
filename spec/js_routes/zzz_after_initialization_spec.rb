# we need to run post_rails_init_spec as the latest
# because it cause unrevertable changes to runtime
# what is why I added "zzz_last" in the beginning

require "sprockets"
require "sprockets/railtie"
require 'spec_helper'
require "fileutils"

describe "after Rails initialization", :slow do
  NAME = Rails.root.join('app', 'assets', 'javascripts', 'routes.js').to_s
  CONFIG_ROUTES = Rails.root.join('config','routes.rb').to_s

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

  before(:each) do
    FileUtils.mkdir_p(Rails.root.join('tmp'))
    FileUtils.rm_rf Rails.root.join('tmp/cache')
    JsRoutes.remove!(NAME)
    JsRoutes.generate!(NAME)
  end

  before(:all) do
    JsRoutes::Engine.install_sprockets!
    Rails.configuration.eager_load = false
    Rails.application.initialize!
  end

  it "should generate routes file" do
    expect(File.exist?(NAME)).to be_truthy
  end

  it "should not rewrite routes file if nothing changed" do
    routes_file_mtime = File.mtime(NAME)
    JsRoutes.generate!(NAME)
    expect(File.mtime(NAME)).to eq(routes_file_mtime)
  end

  it "should rewrite routes file if file content changed" do
    # Change content of existed routes file (add space to the end of file).
    File.open(NAME, 'a') { |f| f << ' ' }
    routes_file_mtime = File.mtime(NAME)
    sleep(0.1)
    JsRoutes.generate!(NAME)
    expect(File.mtime(NAME)).not_to eq(routes_file_mtime)
  end

  describe JsRoutes::Middleware do
    def file_content
      File.read(NAME)
    end

    it "works" do
      JsRoutes.remove!

      real_digest = JsRoutes.digest
      stub_digest = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'

      expect(File.exist?(NAME)).to be(false)
      app = lambda do |env|
        [200, {}, ""]
      end
      middleware = JsRoutes::Middleware.new(app)
      middleware.call({})

      expect(File.exist?(NAME)).to be(true)
      expect(file_content).to include(real_digest)
      JsRoutes.remove!
      middleware.call({})
      expect(File.exist?(NAME)).to be(false)

      allow(JsRoutes).to receive(:digest).and_return(stub_digest)
      middleware.call({})

      expect(File.exist?(NAME)).to be(true)
      expect(file_content).to include(stub_digest)
    end
  end

  describe ".generate!" do
    let(:dir) { Rails.root.join('tmp') }
    it "works" do
      file = dir.join('typed_routes.js')
      JsRoutes.remove!(file)
      expect(File.exist?(file)).to be(false)
      expect(File.exist?(dir.join('typed_routes.d.ts'))).to be(false)
      JsRoutes.generate!(file, module_type: 'ESM', typed: true)
      expect(File.exist?(file)).to be(true)
      expect(File.exist?(dir.join('typed_routes.d.ts'))).to be(true)
    end
  end


  context "JsRoutes::Engine" do
    TEST_ASSET_PATH = Rails.root.join('app','assets','javascripts','test.js')

    before(:all) do
      File.open(TEST_ASSET_PATH,'w') do |f|
        f.puts "function() {}"
      end
    end
    after(:all) do
      FileUtils.rm_f(TEST_ASSET_PATH)
    end

    context "the preprocessor" do
      before(:each) do
        if sprockets_v3? || sprockets_v4?
          expect_any_instance_of(Sprockets::Context).to receive(:depend_on)
        else
          expect(ctx).to receive(:depend_on).with(CONFIG_ROUTES.to_s)
        end
      end
      let!(:ctx) do
        sprockets_context(Rails.application.assets,
                         'js-routes.js',
                         Pathname.new('js-routes.js'))
      end

      context "when dealing with js-routes.js" do
        context "with Rails" do
          context "and initialize on precompile" do
            before(:each) do
              Rails.application.config.assets.initialize_on_precompile = true
            end
            it "should render some javascript" do
              expect(evaluate(ctx, 'js-routes.js')).to match(/utils\.define_module/)
            end
          end
          context "and not initialize on precompile" do
            before(:each) do
              Rails.application.config.assets.initialize_on_precompile = false
            end
            it "should raise an exception if 3 version" do
              expect(evaluate(ctx, 'js-routes.js')).to match(/utils\.define_module/)
            end
          end

        end
      end


    end
    context "when not dealing with js-routes.js" do
      it "should not depend on routes.rb" do
        ctx = sprockets_context(Rails.application.assets,
                                'test.js',
                                TEST_ASSET_PATH)
        expect(ctx).not_to receive(:depend_on)
        evaluate(ctx, 'test.js')
      end
    end
  end
end

describe "JSRoutes thread safety", :slow do
  before do
    begin
      Rails.application.initialize!
    rescue
    end
  end

  it "can produce the routes from multiple threads" do
    threads = 2.times.map do
      Thread.start do
        10.times {
          expect { JsRoutes.generate }.to_not raise_error
        }
      end
    end

    threads.each do |thread|
      thread.join
    end
  end
end
