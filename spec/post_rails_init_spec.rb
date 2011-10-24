require 'spec_helper'
require "fileutils"

describe "after Rails initialization" do
  let(:name) {  "#{File.dirname(__FILE__)}/../routes.js" }

  before(:all) do

    FileUtils.rm_f(name)
    JsRoutes.generate!({:file => name})

    Rails.application.initialize!
  end

  after(:all) do
    FileUtils.rm_f(name)
  end
  
  context '.generate!' do
    it "should generate routes file" do
      File.exists?(name).should be_true 
    end
  end

  if Rails.version >= "3.1"
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
        context "when dealing with js-routes.js" do
          it "should depend on routes.rb" do
            ctx = Sprockets::Context.new(Rails.application.assets,
                                         'js-routes.js',
                                         Pathname.new('js-routes.js'))
            ctx.should_receive(:depend_on).with(Rails.root.join('config','routes.rb'))
            ctx.evaluate('js-routes.js')
          end

          context 'with Rails 3.1.0' do
            it "should render some javascript" do
              Rails.stub!("version").and_return "3.1.0"
              Rails.application.config.assets.initialize_on_precompile = false

              ctx = Sprockets::Context.new(Rails.application.assets,
                                           'js-routes.js',
                                           Pathname.new('js-routes.js'))
              ctx.evaluate('js-routes.js').should =~ /window\.Routes/
            end
          end

          context "with Rails 3.1.1" do
            it "should render some javascript when initialize_on_precompile is true" do
              Rails.stub!("version").and_return "3.1.1"
              Rails.application.config.assets.initialize_on_precompile = true

              ctx = Sprockets::Context.new(Rails.application.assets,
                                           'js-routes.js',
                                           Pathname.new('js-routes.js'))
              ctx.evaluate('js-routes.js').should =~ /window\.Routes/
            end

            it "should raise an exception when initialize_on_precompile is false" do
              Rails.stub!("version").and_return "3.1.1"
              Rails.application.config.assets.initialize_on_precompile = false

              ctx = Sprockets::Context.new(Rails.application.assets,
                                           'js-routes.js',
                                           Pathname.new('js-routes.js'))
              lambda { ctx.evaluate('js-routes.js') }.should raise_error(/Cannot precompile/)
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
  end
end
