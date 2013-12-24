# we need to run post_rails_init_spec as the latest
# because it cause unrevertable changes to runtime
# what is why I added "zzz_last" in the beginning

require 'spec_helper'
require "fileutils"

describe "after Rails initialization" do
  NAME = "#{File.dirname(__FILE__)}/../routes.js"

  before(:all) do
    FileUtils.rm_f(NAME)
    JsRoutes.generate!(NAME)
    Rails.configuration.eager_load = false
    Rails.application.initialize!
  end

  after(:all) do
    FileUtils.rm_f(NAME)
  end

  it "should generate routes file" do
    expect(File.exists?(NAME)).to be_true
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

    it "should have registered a preprocessor" do
      pps = Rails.application.assets.preprocessors
      js_pps = pps['application/javascript']
      expect(js_pps.map(&:name)).to include('Sprockets::Processor (js-routes_dependent_on_routes)')
    end

    context "the preprocessor" do
      before(:each) do
        expect(ctx).to receive(:depend_on).with(Rails.root.join('config','routes.rb'))
      end
      let!(:ctx) do
        Sprockets::Context.new(Rails.application.assets,
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
              expect(ctx.evaluate('js-routes.js')).to match(/window\.Routes/)
            end
          end
          context "and not initialize on precompile" do
            before(:each) do
              Rails.application.config.assets.initialize_on_precompile = false
            end
            it "should raise an exception if 3 version" do
              if 3 == Rails::VERSION::MAJOR
                expect { ctx.evaluate('js-routes.js') }.to raise_error(/Cannot precompile/)
              else
                expect(ctx.evaluate('js-routes.js')).to match(/window\.Routes/)
              end
            end
          end

        end
      end


    end
    context "when not dealing with js-routes.js" do
      it "should not depend on routes.rb" do
        ctx = Sprockets::Context.new(Rails.application.assets,
                                     'test.js',
                                     TEST_ASSET_PATH)
        expect(ctx).not_to receive(:depend_on)
        ctx.evaluate('test.js')
      end
    end
  end
end

describe "JSRoutes thread safety" do
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
