require "spec_helper"

describe JsRoutes, "compatibility with Rails"  do

  before(:each) do
    evaljs(JsRoutes.generate({}))
  end

  it "should generate collection routing" do
    evaljs("Routes.inboxes_path()").should == routes.inboxes_path()
  end

  it "should generate member routing" do
    evaljs("Routes.inbox_path(1)").should == routes.inbox_path(1)
  end

  it "should support 0 as a member parameter" do
    evaljs("Routes.inbox_path(0)").should == routes.inbox_path(0)
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

  it "should support routes with reserved javascript words as parameters" do
    evaljs("Routes.object_path(1, 2)").should == routes.object_path(1,2)
  end

  it "should support url anchor given as parameter" do
    evaljs("Routes.inbox_path(1, {anchor: 'hello'})").should == routes.inbox_path(1, :anchor => "hello")
  end

  it "should support url anchor and get parameters" do
    evaljs("Routes.inbox_path(1, {expanded: true, anchor: 'hello'})").should == routes.inbox_path(1, :expanded => true, :anchor => "hello")
  end

  it "should support engine routes" do
    evaljs("Routes.blog_app_posts_path()").should == blog_routes.posts_path()
  end

  it "should support engine routes with parameter" do
    evaljs("Routes.blog_app_post_path(1)").should == blog_routes.post_path(1)
  end

  it "shouldn't require the format" do
    evaljs("Routes.json_only_path({format: 'json'})").should == routes.json_only_path(:format => 'json')
  end

  it "should support utf-8 route" do
    evaljs("Routes.hello_path()").should == routes.hello_path
  end

  it "should support root_path" do
    evaljs("Routes.root_path()").should == routes.root_path
  end

  describe "get paramters" do
    it "should support simple get parameters" do
      evaljs("Routes.inbox_path(1, {format: 'json', lang: 'ua', q: 'hello'})").should == routes.inbox_path(1, :lang => "ua", :q => "hello", :format => "json")
    end

    it "should support array get parameters" do
      evaljs("Routes.inbox_path(1, {hello: ['world', 'mars']})").should == routes.inbox_path(1, :hello => [:world, :mars])
    end

    it "should support nested get parameters" do
      evaljs("Routes.inbox_path(1, {format: 'json', env: 'test', search: { category_ids: [2,5], q: 'hello'}})").should ==
        routes.inbox_path(1, :env => 'test', :search => {:category_ids => [2,5], :q => "hello"}, :format => "json")
    end

    it "should support null and undefined parameters" do
      evaljs("Routes.inboxes_path({uri: null, key: undefined})").should == routes.inboxes_path(:uri => nil, :key => nil)
    end

    it "should escape get parameters" do
      evaljs("Routes.inboxes_path({uri: 'http://example.com'})").should == routes.inboxes_path(:uri => 'http://example.com')
    end
  end


  context "routes globbing" do
    it "should be supported as parameters" do
      evaljs("Routes.book_path('thrillers', 1)").should == routes.book_path('thrillers', 1)
    end

    it "should support routes globbing as array" do
      evaljs("Routes.book_path(['thrillers'], 1)").should == routes.book_path(['thrillers'], 1)
    end

    it "should bee support routes globbing as array" do
      evaljs("Routes.book_path([1, 2, 3], 1)").should == routes.book_path([1, 2, 3], 1)
    end

    it "should bee support routes globbing as hash" do
      evaljs("Routes.book_path('a_test/b_test/c_test', 1)").should == routes.book_path('a_test/b_test/c_test', 1)
    end

    it "should support routes globbing as array with optional params" do
      evaljs("Routes.book_path([1, 2, 3, 5], 1, {c: '1'})").should == routes.book_path([1, 2, 3, 5], 1, { :c => "1" })
    end

    it "should support routes globbing in book_title route as array" do
      evaljs("Routes.book_title_path('john', ['thrillers', 'comedian'])").should == routes.book_title_path('john', ['thrillers', 'comedian'])
    end

    it "should support routes globbing in book_title route as array with optional params" do
      evaljs("Routes.book_title_path('john', ['thrillers', 'comedian'], {some_key: 'some_value'})").should == routes.book_title_path('john', ['thrillers', 'comedian'], {:some_key => 'some_value'})
    end
  end

  context "when jQuery is present" do
    before do
      evaljs("window.jQuery = {};")
      jscontext[:parameterize] = lambda {|object| _value.to_param}
      evaljs("window.jQuery.param = parameterize")
    end

    shared_examples_for "serialization" do
      it "should support serialization of objects" do
        evaljs("window.jQuery.param(#{_value.to_json})").should == _value.to_param
        evaljs("Routes.inboxes_path(#{_value.to_json})").should == routes.inboxes_path(_value)
        evaljs("Routes.inbox_path(1, #{_value.to_json})").should == routes.inbox_path(1, _value)
      end
    end
    context "when parameters is a hash" do
      let(:_value) do
        {:a => {:b => 'c'}, :q => [1,2]}
      end
      it_should_behave_like 'serialization'
    end
    context "when parameters is null" do
      let(:_value) do
        nil
      end
      it_should_behave_like 'serialization'
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

      it "should not require the optional parts as arguments" do
        #TODO: fix this inconsistence
        pending
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

  context "when wrong parameters given" do

    it "should throw Exception if not enough parameters" do
      lambda {
        evaljs("Routes.inbox_path()")
      }.should raise_error(js_error_class)
    end
    it "should throw Exception if required parameter is not defined" do
      lambda {
        evaljs("Routes.inbox_path(null)")
      }.should raise_error(js_error_class)
    end

    it "should throw Exceptions if when there is too many parameters" do
      lambda {
        evaljs("Routes.inbox_path(1,2)")
      }.should raise_error(js_error_class)
    end
  end

  context "when javascript engine without Array#indexOf is used" do
    before(:each) do
      evaljs("Array.prototype.indexOf = null")
    end
    it "should still work correctly" do
      evaljs("Routes.inboxes_path()").should == routes.inboxes_path()
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

    context "when globbing" do
      it "should prefer to_param property over id property" do
        evaljs("Routes.book_path({id: 1, to_param: 'my'}, 1)").should == routes.book_path(inbox, 1)
      end

      it "should call to_param if it is a function" do
        evaljs("Routes.book_path({id: 1, to_param: function(){ return 'my';}}, 1)").should == routes.book_path(inbox, 1)
      end

      it "should call id if it is a function" do
        evaljs("Routes.book_path({id: function() { return 'technical';}}, 1)").should == routes.book_path('technical', 1)
      end

      it "should support options argument" do
        evaljs(
          "Routes.book_path({id:1, to_param: 'my'}, {id:2}, {custom: true, format: 'json'})"
        ).should == routes.book_path(inbox, 2, :custom => true, :format => "json")
      end
    end
  end
end
