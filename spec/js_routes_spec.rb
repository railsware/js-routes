require 'spec_helper'
require "fileutils"


describe JsRoutes do
  before(:each) do
    Rails.application.stub!(:reload_routes!).and_return(true)
    evaljs(_presetup)
    evaljs(JsRoutes.generate(_options))
  end

  let(:_presetup) { "this;" }
  let(:_options) { {} }

  let(:routes) { App.routes.url_helpers }
  let(:blog_routes) { BlogEngine::Engine.routes.url_helpers }

  describe "compatibility with Rails" do

    it "should generate collection routing" do
      evaljs("Routes.inboxes_path()").should == routes.inboxes_path()
    end

    it "should generate member routing" do
      evaljs("Routes.inbox_path(1)").should == routes.inbox_path(1)
    end

    it "should generate nested routing with one parameter" do
      evaljs("Routes.inbox_messages_path(1)").should == routes.inbox_messages_path(1)
    end

    it "should generate nested routing" do
      evaljs("Routes.inbox_message_path(1,2)").should == routes.inbox_message_path(1, 2)
    end

    it "should generate routing with format" do
      evaljs("Routes.inbox_path(1, {format: 'json'})").should == routes.inbox_path(1, :format => "json")
    end

    it "should support simple get parameters" do
      evaljs("Routes.inbox_path(1, {format: 'json', lang: 'ua', q: 'hello'})").should == routes.inbox_path(1, :lang => "ua", :q => "hello", :format => "json")
    end

    it "should support array get parameters" do
      evaljs("Routes.inbox_path(1, {hello: ['world', 'mars']})").should == routes.inbox_path(1, :hello => [:world, :mars])
    end

    it "should support null and undefined parameters" do
      evaljs("Routes.inboxes_path({uri: null, key: undefined})").should == routes.inboxes_path(:uri => nil, :key => nil)
    end

    it "should escape get parameters" do
      evaljs("Routes.inboxes_path({uri: 'http://example.com'})").should == routes.inboxes_path(:uri => 'http://example.com')
    end

    it "should support routes with reserved javascript words as parameters" do
      evaljs("Routes.object_path(1, 2)").should == routes.object_path(1,2)
    end

    it "should support url anchor given as parameter" do
      evaljs("Routes.inbox_path(1, {anchor: 'hello'})").should == routes.inbox_path(1, :anchor => "hello")
    end
    
    it "should support engine routes" do
      evaljs("Routes.blog_app_posts_path()").should == blog_routes.posts_path()
    end
    
    it "should support engine routes with parameter" do
      evaljs("Routes.blog_app_post_path(1)").should == blog_routes.post_path(1)
    end

    it "shouldn't require the format" do
      evaljs("Routes.json_only_path({format: 'json'})").should == routes.json_only_path('json')
    end

    context "routes globbing" do
      it "should be supported as parameters" do
        evaljs("Routes.book_path('thrillers', 1)").should == routes.book_path('thrillers', 1)
      end

      xit "should support routes globbing as hash" do
        evaljs("Routes.book_path(1, {section: 'thrillers'})").should == routes.book_path(1, :section => 'thrillers')
      end

      xit "should bee support routes globbing as hash" do
        evaljs("Routes.book_path(1)").should == routes.book_path(1)
      end
    end

    context "using optional path fragments" do
      context "including not optional parts" do
        it "should include everything that is not optional" do
          evaljs("Routes.foo_path()").should == routes.foo_path
        end
      end

      context "but not including them" do
        it "should not include the optional parts" do
          evaljs("Routes.things_path()").should == routes.things_path
        end

        xit "should not require the optional parts as arguments" do
          #TODO: fix this inconsistence
          evaljs("Routes.thing_path(null, 5)").should == routes.thing_path(nil, 5)
        end

        it "should treat undefined as non-given optional part" do
          evaljs("Routes.thing_path(5, {optional_id: undefined})").should == routes.thing_path(5, :optional_id => nil)
        end

        it "should treat null as non-given optional part" do
          evaljs("Routes.thing_path(5, {optional_id: null})").should == routes.thing_path(5, :optional_id => nil)
        end
      end

      context "and including them" do
        it "should include the optional parts" do
          evaljs("Routes.things_path({optional_id: 5})").should == routes.things_path(:optional_id => 5)
        end
      end
    end
  end

  context "when wrong parameters given" do
    
    it "should throw Exception if not enough parameters" do
      lambda {
        evaljs("Routes.inbox_path()")
      }.should raise_error(V8::JSError)
    end
    it "should throw Exception if required parameter is not defined" do
      lambda {
        evaljs("Routes.inbox_path(null)")
      }.should raise_error(V8::JSError)
    end

    it "should throw Exceptions if when there is too many parameters" do
      lambda {
        evaljs("Routes.inbox_path(1,2)")
      }.should raise_error(V8::JSError)
    end
  end

  context "when exclude is specified" do
    
    let(:_options) { {:exclude => /^admin_/} }

    it "should exclude specified routes from file" do
      evaljs("Routes.admin_users_path").should be_nil
    end

    it "should not exclude routes not under specified pattern" do
      evaljs("Routes.inboxes_path()").should_not be_nil
    end
  end
  context "when include is specified" do
    
    let(:_options) { {:include => /^admin_/} }

    it "should exclude specified routes from file" do
      evaljs("Routes.admin_users_path()").should_not be_nil
    end

    it "should not exclude routes not under specified pattern" do
      evaljs("Routes.inboxes_path").should be_nil
    end
  end

  context "when prefix with trailing slash is specified" do
    
    let(:_options) { {:prefix => "/myprefix/" } }

    it "should render routing with prefix" do
        evaljs("Routes.inbox_path(1)").should == "/myprefix#{routes.inbox_path(1)}"
    end

    it "should render routing with prefix set in JavaScript" do
      evaljs("Routes.options.prefix = '/newprefix/'")
      evaljs("Routes.inbox_path(1)").should == "/newprefix#{routes.inbox_path(1)}"
    end

  end
  
  context "when prefix without trailing slash is specified" do
    
    let(:_options) { {:prefix => "/myprefix" } }

    it "should render routing with prefix" do
      evaljs("Routes.inbox_path(1)").should == "/myprefix#{routes.inbox_path(1)}"
    end
    
    it "should render routing with prefix set in JavaScript" do
      evaljs("Routes.options.prefix = '/newprefix'")
      evaljs("Routes.inbox_path(1)").should == "/newprefix#{routes.inbox_path(1)}"
    end

  end

  context "when default_format is specified" do
    let(:_options) { {:default_format => "json"} }
    
    it "should render routing with default_format" do
      evaljs("Routes.inbox_path(1)").should == routes.inbox_path(1, :format => "json")
    end

    it "should override default_format when spefified implicitly" do
      evaljs("Routes.inbox_path(1, {format: 'xml'})").should == routes.inbox_path(1, :format => "xml")
    end

    it "should override nullify implicitly when specified implicitly" do
      evaljs("Routes.inbox_path(1, {format: null})").should == routes.inbox_path(1)
    end

    it "shouldn't include the format when {:format => false} is specified" do
      evaljs("Routes.no_format_path()").should == routes.no_format_path
    end

    it "shouldn't require the format" do
      evaljs("Routes.json_only_path()").should == routes.json_only_path('json')
    end
  end

  describe "when namespace option is specified" do
    let(:_options) { {:namespace => "PHM"} }
    it "should use this namespace for routing" do
      evaljs("window.Routes").should be_nil
      evaljs("PHM.inbox_path").should_not be_nil
    end
  end

  describe "when nested namespace option is specified" do 
    context "and defined on client" do
      let(:_presetup) { "window.PHM = {}" }
      let(:_options) { {:namespace => "PHM.Routes"} }
      it "should use this namespace for routing" do
        evaljs("PHM.Routes.inbox_path").should_not be_nil
      end
    end

    context "but undefined on client" do
      let(:_options) { {:namespace => "PHM.Routes"} }
      it "should initialize namespace" do
        evaljs("window.PHM.Routes.inbox_path").should_not be_nil
      end 
    end

    context "and some parts are defined" do
      let(:_presetup) { "window.PHM = { Utils: {} };" }
      let(:_options) { {:namespace => "PHM.Routes"} }
      it "should not overwrite existing parts" do
        evaljs("window.PHM.Utils").should_not be_nil
        evaljs("window.PHM.Routes.inbox_path").should_not be_nil
      end
    end
  end

  context "when arguments are objects" do

    let(:inbox) {Struct.new(:id, :to_param).new(1,"my")}

    it "should use id property of the object in path" do
      evaljs("Routes.inbox_path({id: 1})").should == routes.inbox_path(1)
    end

    it "should prefer to_param property over id property" do
      evaljs("Routes.inbox_path({id: 1, to_param: 'my'})").should == routes.inbox_path(inbox)
    end

    it "should call to_param if it is a function" do
      evaljs("Routes.inbox_path({id: 1, to_param: function(){ return 'my';}})").should == routes.inbox_path(inbox)
    end

    it "should call id if it is a function" do
      evaljs("Routes.inbox_path({id: function() { return 1;}})").should == routes.inbox_path(1)
    end

    it "should support options argument" do
      evaljs(
        "Routes.inbox_message_path({id:1, to_param: 'my'}, {id:2}, {custom: true, format: 'json'})"
      ).should == routes.inbox_message_path(inbox, 2, :custom => true, :format => "json")
    end
  end


  describe "generated js" do
    subject { JsRoutes.generate }
    it "should have correct function without arguments signature" do
      should include("inboxes_path: function(options)")
    end
    it "should have correct function with arguments signature" do
      should include("inbox_message_path: function(_inbox_id, _id, options)")
    end
    it "should have correct function signature with Ruby 1.8.7 and unordered hash" do
      should include("inbox_message_attachment_path: function(_inbox_id, _message_id, _id, options)")
    end
  end

  describe ".generate!" do

    let(:name) {  "#{File.dirname(__FILE__)}/../routes.js" }

    before(:each) do
      FileUtils.rm_f(name)
      JsRoutes.generate!({:file => name})
    end

    it "should not generate file before initialization" do
      File.exists?(name).should be_false
    end

    after(:all) do
      FileUtils.rm_f(name)
    end
  end
end
