require 'spec_helper'
require "fileutils"



describe JsRoutes do
  before(:each) do
    Rails.application.stub!(:reload_routes!).and_return(true)
    evaljs("var window = this;")
    evaljs(JsRoutes.generate(_options))
  end

  let(:_options) { {} }

  it "should generate collection routing" do
    evaljs("Routes.inboxes_path()").should == "/inboxes"
  end

  it "should generate member routing" do
    evaljs("Routes.inbox_path(1)").should == "/inboxes/1"
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

  context "when exclude is specified" do
    
    let(:_options) { {:exclude => /^admin_/} }

    it "should exclude specified routes from file" do
      evaljs("Routes.admin_users_path").should be_nil
    end

    it "should not exclude routes not under specified pattern" do
      evaljs("Routes.inboxes_path()").should_not be_nil
    end
  end

  context "when default_format is specified" do
    let(:_options) { {:default_format => "json"} }
    
    it "should render routing with default_format" do
      evaljs("Routes.inbox_path(1)").should == "/inboxes/1.json"
    end

    it "should override default_format implicitly" do
      evaljs("Routes.inbox_path(1, {format: 'xml'})").should == "/inboxes/1.xml"
    end

  end

  context "when namspace option is specified" do
    let(:_options) { {:namespace => "PHM"} }
    it "should use this name space for routing" do
      evaljs("window.Routes").should be_nil
      evaljs("PHM.inbox_path").should_not be_nil
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
