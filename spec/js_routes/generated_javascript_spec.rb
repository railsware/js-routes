require 'spec_helper'
require "fileutils"


describe JsRoutes do
  before(:each) do
    evaljs(JsRoutes.generate)
  end

  describe "generated js" do
    subject { JsRoutes.generate }
    it "should call route function for each route" do
      is_expected.to include("inboxes_path: route(")
      is_expected.to include("inbox_message_path: route(")
      is_expected.to include("inbox_message_attachment_path: route(")
    end
    it "should have correct function with arguments signature" do
      pending 'no more arguments signature with the route function (is that bad?)'
      is_expected.to include("inbox_message_path: function(_inbox_id, _id, options)")
    end
    it "should have correct function signature with unordered hash" do
      pending 'no more arguments signature with the route function (is that bad?)'
      is_expected.to include("inbox_message_attachment_path: function(_inbox_id, _message_id, _id, options)")
    end

    it "routes should be sorted in alphabetical order" do
      expect(subject.index("book_path")).to be <= subject.index("inboxes_path")
    end
  end

  describe ".generate!" do

    let(:name) { "#{File.dirname(__FILE__)}/../routes.js" }

    before(:each) do
      FileUtils.rm_f(name)
      JsRoutes.generate!({:file => name})
    end

    after(:all) do
      FileUtils.rm_f("#{File.dirname(__FILE__)}/../routes.js") # let(:name) is not available here
    end

    it "should not generate file before initialization" do
      # This method is alread fixed in Rails master
      # But in 3.2 stable we need to hack it like this
      if Rails.application.instance_variable_get("@initialized")
        pending
      end
      expect(File.exists?(name)).to be_falsey
    end

  end

  describe "compiled javascript asset" do
    subject { ERB.new(File.read("app/assets/javascripts/js-routes.js.erb")).result(binding) }
    it "should have js routes code" do
      is_expected.to include("inbox_message_path: route(")
    end
  end
end
