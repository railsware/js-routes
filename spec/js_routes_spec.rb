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
    evaljs("Routes.inbox_message_path(1)").should == "/inboxes/1/messages"
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
    #TODO: this doesn't actually test what it should test because the parameter name is return_id
    #need to find the real way to test
    evaljs("Routes.return_path(1)").should == "/returns/1"
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

  context "when default_format is specified" do
    let(:_options) { {:default_format => "json"} }
    
    it "should render routing with default_format" do
      evaljs("Routes.inbox_path(1)").should == "/inboxes/1.json"
    end

    it "should override default_format wehn spefified implicitly" do
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
    it "should use id property of the object" do
      evaljs("Routes.inbox_path({id: 1})").should == "/inboxes/1"
    end

    it "should use prefer to_param property over id property" do
      evaljs("Routes.inbox_path({id: 1, to_param: 'my'})").should == "/inboxes/my"
    end

    it "should support still support options argument" do
      evaljs("Routes.inbox_message_path({id:1, to_param: 'my'}, {id:2}, {custom: true})").should == "/inboxes/my/messages/2?custom=true"
    end
  end

  describe "generated js" do
    subject { JsRoutes.generate }
    it "should have correct function signature" do
      subject.should include("inbox_message_path: function(_inbox_id, _id, options)")
    end
  end

  describe ".generate!" do
    let(:name) {  "#{File.dirname(__FILE__)}/../routes.js" }
    it "should generate routes file" do
      FileUtils.rm_f(name)
      JsRoutes.generate!({:file => name})
      File.exists?(name).should be_true 
    end
    after(:all) do
      FileUtils.rm_f(name)
    end
  end

end
