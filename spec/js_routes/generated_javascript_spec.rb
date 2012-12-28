require 'spec_helper'
require "fileutils"


describe JsRoutes do
  before(:each) do
    evaljs(JsRoutes.generate)
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

    it "routes should be sorted in alphabetical order" do
      subject.index("book_path").should <= subject.index("inboxes_path")
    end
  end

  describe ".generate!" do

    let(:name) {  "#{File.dirname(__FILE__)}/../routes.js" }

    before(:each) do
      FileUtils.rm_f(name)
      JsRoutes.generate!({:file => name})
    end

    it "should not generate file before initialization" do
      # This method is alread fixed in Rails master
      # But in 3.2 stable we need to hack it like this
      if Rails.application.instance_variable_get("@initialized")
        pending
      end
      File.exists?(name).should be_false
    end

    after(:all) do
      FileUtils.rm_f(name)
    end
  end

  describe "compiled javascript asset" do
    subject { ERB.new(File.read("app/assets/javascripts/js-routes.js.erb")).result(binding) }
    it "should have js routes code" do
      should include("inbox_message_path: function(_inbox_id, _id, options)")
    end
  end
end
