require 'spec_helper'
require "fileutils"


describe JsRoutes do
  before(:each) do
    Rails.application.stub!(:reload_routes!).and_return(true)
    evaljs("var window = this;")
    evaljs(_presetup)
    evaljs(JsRoutes.generate(_options))
  end

  let(:_presetup) { "this;" }
  let(:_options) { {} }

  it "should generate collection routing" do
    evaljs("Routes.inboxes_path()").should == "/inboxes"
  end

  it "should generate member routing" do
    evaljs("Routes.inbox_path(1)").should == "/inboxes/1"
  end

  it "should generate nested routing with one parameter" do
    evaljs("Routes.inbox_messages_path(1)").should == "/inboxes/1/messages"
  end

  it "should generate nested routing" do
    evaljs("Routes.inbox_message_path(1,2)").should == "/inboxes/1/messages/2"
  end

  it "should generate routing with format" do
    evaljs("Routes.inbox_path(1, {format: 'json'})").should == "/inboxes/1.json"
  end

  it "should support get parameters" do
    evaljs("Routes.inbox_path(1, {format: 'json', q: 'hello', lang: 'ua'})").should == "/inboxes/1.json?q=hello&lang=ua"
  end

  it "should support routes with reserved javascript words as parameters" do
    evaljs("Routes.object_path(1, 2)").should == "/returns/1/objects/2"
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
        evaljs("Routes.inbox_path(1)").should == "/myprefix/inboxes/1"
    end

    it "should render routing with prefix set in JavaScript" do
      evaljs("Routes.options.prefix = '/newprefix/'")
      evaljs("Routes.inbox_path(1)").should == "/newprefix/inboxes/1"
    end

  end
  
  context "when prefix without trailing slash is specified" do
    
    let(:_options) { {:prefix => "/myprefix" } }

    it "should render routing with prefix" do
      evaljs("Routes.inbox_path(1)").should == "/myprefix/inboxes/1"
    end
    
    it "should render routing with prefix set in JavaScript" do
      evaljs("Routes.options.prefix = '/newprefix'")
      evaljs("Routes.inbox_path(1)").should == "/newprefix/inboxes/1"
    end

  end

  context "when default_format is specified" do
    let(:_options) { {:default_format => "json"} }
    
    it "should render routing with default_format" do
      evaljs("Routes.inbox_path(1)").should == "/inboxes/1.json"
    end

    it "should override default_format when spefified implicitly" do
      evaljs("Routes.inbox_path(1, {format: 'xml'})").should == "/inboxes/1.xml"
    end

    it "should override nullify implicitly when specified implicitly" do
      evaljs("Routes.inbox_path(1, {format: null})").should == "/inboxes/1"
    end

  end

  context "when namspace option is specified" do
    let(:_options) { {:namespace => "PHM"} }
    it "should use this name space for routing" do
      evaljs("window.Routes").should be_nil
      evaljs("PHM.inbox_path").should_not be_nil
    end
    
  end
  context "when nested namspace option is specified" do
    let(:_presetup) { "window.PHM = {}" }
    let(:_options) { {:namespace => "PHM.Routes"} }
    it "should use this name space for routing" do
      evaljs("PHM.Routes.inbox_path").should_not be_nil
    end
  end

  context "when arguments are objects" do
    it "should use id property of the object in path" do
      evaljs("Routes.inbox_path({id: 1})").should == "/inboxes/1"
    end

    it "should prefer to_param property over id property" do
      evaljs("Routes.inbox_path({id: 1, to_param: 'my'})").should == "/inboxes/my"
    end

    it "should support options argument" do
      evaljs("Routes.inbox_message_path({id:1, to_param: 'my'}, {id:2}, {custom: true, format: 'json'})").should == "/inboxes/my/messages/2.json?custom=true"
    end
  end

  context "using optional path fragments" do
    context "but not including them" do
      it "should not include the optional parts" do
        evaljs("Routes.things_path()").should == "/things"
      end

      it "should treat undefined as non-given optional part" do
        evaljs("Routes.thing_path(undefined, 5)").should == "/things/5"
      end

      it "should treat null as non-given optional part" do
        evaljs("Routes.thing_path(null, 5)").should == "/things/5"
      end
    end

    context "and including them" do
      it "should include the optional parts" do
        evaljs("Routes.things_path(5)").should == "/optional/5/things"
      end
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
      # prevent warning
      Rails.configuration.active_support.deprecation = :log

      FileUtils.rm_f(name)
      JsRoutes.generate!({:file => name})
    end

    it "should not generate file at once" do
      File.exists?(name).should be_false
    end

    context "after Rails initialization" do
      before(:each) do
        Rails.application.initialize!
      end
      it "should generate routes file only after rails initialization" do
        File.exists?(name).should be_true 
      end
    end

    after(:all) do
      FileUtils.rm_f(name)
    end
  end

end
