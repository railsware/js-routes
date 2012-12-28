require 'spec_helper'
require "fileutils"

describe "after Rails initialization" do
  let(:name) {  "#{File.dirname(__FILE__)}/../routes.js" }

  before(:all) do

    FileUtils.rm_f(name)
    JsRoutes.generate!(name)


    Rails.application.initialize!
  end

  after(:all) do
    FileUtils.rm_f(name)
  end

  it "should generate routes file" do
    File.exists?(name).should be_true
  end

  context "JsRoutes::Engine" do

    let(:test_asset_path) {
      Rails.root.join('app','assets','javascripts','test.js')
    }

    before(:all) do
      File.open(test_asset_path,'w') do |f|
        f.puts "function() {}"
      end
    end
    after(:all) do
      FileUtils.rm_f(test_asset_path)
    end

    it "should have registered a preprocessor" do
      pps = Rails.application.assets.preprocessors
      js_pps = pps['application/javascript']
      js_pps.map(&:name).should include('Sprockets::Processor (js-routes_dependent_on_routes)')
    end

    context "the preprocessor" do
      before(:each) do
        ctx.should_receive(:depend_on).with(Rails.root.join('config','routes.rb'))
      end
      let!(:ctx) do
        Sprockets::Context.new(Rails.application.assets,
                               'js-routes.js',
                               Pathname.new('js-routes.js'))

      end
      context "when dealing with js-routes.js" do


        context "with Rails 3.1.1" do
          context "and initialize on precompile" do
            before(:each) do
              Rails.application.config.assets.initialize_on_precompile = true
            end
            it "should render some javascript" do
              ctx.evaluate('js-routes.js').should =~ /window\.Routes/
            end
          end
          context "and not initialize on precompile" do
            before(:each) do
              Rails.application.config.assets.initialize_on_precompile = false
            end
            it "should raise an exception" do
              lambda { ctx.evaluate('js-routes.js') }.should raise_error(/Cannot precompile/)
            end
          end

        end
      end


    end
    context "when not dealing with js-routes.js" do
      it "should not depend on routes.rb" do
        ctx = Sprockets::Context.new(Rails.application.assets,
                                     'test.js',
                                     test_asset_path)
        ctx.should_not_receive(:depend_on)
        ctx.evaluate('test.js')
      end
    end
  end
end
