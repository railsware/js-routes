require 'spec_helper'

describe JsRoutes, "options" do
  
  before(:each) do
    evaljs(_presetup)
    with_warnings(_warnings) do
      evaljs(JsRoutes.generate(_options))
    end
  end

  let(:_presetup) { "this;" }
  let(:_options) { {} }
  let(:_warnings) { true }

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

  context "when prefix with http:// is specified" do
    
    let(:_options) { {:prefix => "http://localhost:3000" } }

    it "should render routing with prefix" do
      evaljs("Routes.inbox_path(1)").should == _options[:prefix] + routes.inbox_path(1)
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
    let(:_warnings) { nil }
    
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
      evaljs("Routes.json_only_path()").should == routes.json_only_path(:format => 'json')
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

  describe "default_url_options" do
    context "with optional route parts" do
      let(:_options) { {:default_url_options => {:optional_id => "12", :format => "json"}}}
      it "should use this opions to fill optional parameters" do
        evaljs("Routes.things_path()").should == routes.things_path(:optional_id => 12, :format => "json")
      end
    end

    context "with required route parts" do
      let(:_options) { {:default_url_options => {:inbox_id => "12"}} }
      it "should use this opions to fill optional parameters" do
        pending
        evaljs("Routes.inbox_messages_path()").should == routes.inbox_messages_path(:inbox_id => 12)
      end
    end
  end
end
