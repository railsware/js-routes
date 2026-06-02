require "spec_helper"

describe JsRoutes, "compatibility with Rails" do
  before do
    evallib(module_type: nil, namespace: "Routes")
  end

  it "generates collection routing" do
    expectjs("Routes.inboxes_path()").to eq(test_routes.inboxes_path)
  end

  it "generates member routing" do
    expectjs("Routes.inbox_path(1)").to eq(test_routes.inbox_path(1))
  end

  it "raises error if required argument is not passed", :aggregate_failures do
    expect { evaljs("Routes.thing_path()") }
      .to raise_error(/Route missing required keys: id/)
    expect { evaljs("Routes.search_path()") }
      .to raise_error(/Route missing required keys: q/)
    expect { evaljs("Routes.book_path()") }
      .to raise_error(/Route missing required keys: section, title/)
    expect { evaljs("Routes.book_title_path()") }
      .to raise_error(/Route missing required keys: title/)

    expectjs("try {Routes.thing_path()} catch (e) { e.name }").to eq("ParametersMissing")
    expectjs("try {Routes.thing_path()} catch (e) { e.keys }").to eq(["id"])
  end

  it "produces error stacktraces including function names" do
    stacktrace = evaljs("
        (function(){
          try {
            Routes.thing_path()
          } catch(e) {
            return e.stack;
          }
        })()
      ")
    expect(stacktrace).to include "thing_path"
  end

  it "supports 0 as a member parameter" do
    expectjs("Routes.inbox_path(0)").to eq(test_routes.inbox_path(0))
  end

  it "generates nested routing with one parameter" do
    expectjs("Routes.inbox_messages_path(1)").to eq(test_routes.inbox_messages_path(1))
  end

  it "generates nested routing" do
    expectjs("Routes.inbox_message_path(1,2)").to eq(test_routes.inbox_message_path(1, 2))
  end

  it "generates routing with format" do
    expectjs("Routes.inbox_path(1, {format: 'json'})").to eq(test_routes.inbox_path(1, format: "json"))
  end

  it "supports routes with reserved javascript words as parameters" do
    expectjs("Routes.object_path(1, 2)").to eq(test_routes.object_path(1, 2))
  end

  it "supports routes with trailing_slash" do
    expectjs("Routes.inbox_path(1, {trailing_slash: true})").to eq(test_routes.inbox_path(1, trailing_slash: true))
  end

  it "supports url anchor given as parameter" do
    expectjs("Routes.inbox_path(1, {anchor: 'hello'})").to eq(test_routes.inbox_path(1, anchor: "hello"))
  end

  it "supports url anchor and get parameters" do
    expectjs("Routes.inbox_path(1, {expanded: true, anchor: 'hello'})").to eq(test_routes.inbox_path(1, expanded: true, anchor: "hello"))
  end

  it "supports required parameters given as options hash" do
    expectjs("Routes.search_path({q: 'hello'})").to eq(test_routes.search_path(q: "hello"))
  end

  it "uses irregular ActiveSupport pluralizations" do
    expectjs("Routes.budgies_path()").to eq(test_routes.budgies_path)
    expectjs("Routes.budgie_path(1)").to eq(test_routes.budgie_path(1))
    expectjs("Routes.budgy_path").to be_nil
    expectjs("Routes.budgie_descendents_path(1)").to eq(test_routes.budgie_descendents_path(1))
  end

  describe "url parameters encoding" do
    it "supports route with parameters containing symbols that need URI-encoding", :aggregate_failures do
      expectjs("Routes.inbox_path('#hello')").to eq(test_routes.inbox_path("#hello"))
      expectjs("Routes.inbox_path('some param')").to eq(test_routes.inbox_path("some param"))
      expectjs("Routes.inbox_path('some param with more & more encode symbols')").to eq(test_routes.inbox_path("some param with more & more encode symbols"))
    end

    it "supports route with parameters containing symbols not need URI-encoding", :aggregate_failures do
      expectjs("Routes.inbox_path(':some_id')").to eq(test_routes.inbox_path(":some_id"))
      expectjs("Routes.inbox_path('.+')").to eq(test_routes.inbox_path(".+"))
    end

    it "supports emoji characters", :aggregate_failures do
      expectjs("Routes.inbox_path('💗')").to eq(test_routes.inbox_path("💗"))
    end
  end

  describe "when route has defaults" do
    it "supports route default format" do
      expectjs("Routes.api_purchases_path()").to eq(test_routes.api_purchases_path)
    end

    it "supports route default subdomain" do
      expectjs("Routes.backend_root_path()").to eq(test_routes.backend_root_path)
    end

    it "supports default format override" do
      expectjs("Routes.api_purchases_path({format: 'xml'})").to eq(test_routes.api_purchases_path(format: "xml"))
    end

    it "supports default format override by passing it in args" do
      expectjs("Routes.api_purchases_path('xml')").to eq(test_routes.api_purchases_path("xml"))
    end

    it "doesn't apply defaults to path" do
      expectjs("Routes.with_defaults_path()").to eq(test_routes.with_defaults_path)
      expectjs("Routes.with_defaults_path({format: 'json'})").to eq(test_routes.with_defaults_path(format: "json"))
    end
  end

  context "with rails engines" do
    it "supports simple route" do
      expectjs("Routes.blog_app_posts_path()").to eq(blog_routes.posts_path)
    end

    it "supports root route" do
      expectjs("Routes.blog_app_path()").to eq(test_routes.blog_app_path)
    end

    it "supports route with parameters" do
      expectjs("Routes.blog_app_post_path(1)").to eq(blog_routes.post_path(1))
    end

    it "supports root path" do
      expectjs("Routes.blog_app_root_path()").to eq(blog_routes.root_path)
    end

    it "supports single route mapping" do
      expectjs("Routes.support_path({page: 3})").to eq(test_routes.support_path(page: 3))
    end

    it "works" do
      expectjs("Routes.planner_manage_path({locale: 'ua'})").to eq(planner_routes.manage_path(locale: "ua"))
      expectjs("Routes.planner_manage_path()").to eq(planner_routes.manage_path)
    end
  end

  it "does not require the format" do
    expectjs("Routes.json_only_path({format: 'json'})").to eq(test_routes.json_only_path(format: "json"))
  end

  it "serializes object with empty string value" do
    expectjs("Routes.inboxes_path({a: '', b: 1})").to eq(test_routes.inboxes_path(a: "", b: 1))
  end

  it "supports utf-8 route" do
    expectjs("Routes.hello_path()").to eq(test_routes.hello_path)
  end

  it "supports root_path" do
    expectjs("Routes.root_path()").to eq(test_routes.root_path)
  end

  describe "params parameter" do
    it "works" do
      expectjs("Routes.inboxes_path({params: {key: 'value'}})").to eq(test_routes.inboxes_path(params: {key: "value"}))
    end

    it "allows keyword key as a query parameter" do
      expectjs("Routes.inboxes_path({params: {anchor: 'a', params: 'p'}})").to eq(test_routes.inboxes_path(params: {anchor: "a", params: "p"}))
    end

    it "throws when value is not an object" do
      expect {
        evaljs("Routes.inboxes_path({params: 1})")
      }.to raise_error(js_error_class)
    end
  end

  describe "get parameters" do
    it "supports simple get parameters" do
      expectjs("Routes.inbox_path(1, {format: 'json', lang: 'ua', q: 'hello'})").to eq(test_routes.inbox_path(1, lang: "ua", q: "hello", format: "json"))
    end

    it "supports array get parameters" do
      expectjs("Routes.inbox_path(1, {hello: ['world', 'mars']})").to eq(test_routes.inbox_path(1, hello: [:world, :mars]))
    end

    it "supports empty array get parameters" do
      expectjs("Routes.inboxes_path({ a: [], b: {} })").to eq(test_routes.inboxes_path({a: [], b: {}}))
    end

    context "object without prototype" do
      before do
        evaljs("let params = Object.create(null); params.q = 'hello';")
        evaljs("let inbox = Object.create(null); inbox.to_param = 1;")
      end

      it "stills work correctly" do
        expectjs("Routes.inbox_path(inbox, params)").to eq(
          test_routes.inbox_path(1, q: "hello")
        )
      end
    end

    it "supports nested get parameters" do
      expectjs("Routes.inbox_path(1, {format: 'json', env: 'test', search: { category_ids: [2,5], q: 'hello'}})").to eq(
        test_routes.inbox_path(1, env: "test", search: {category_ids: [2, 5], q: "hello"}, format: "json")
      )
    end

    it "supports null and undefined parameters" do
      expectjs("Routes.inboxes_path({uri: null, key: undefined})").to eq(test_routes.inboxes_path(uri: nil, key: nil))
    end

    it "escapes get parameters" do
      expectjs("Routes.inboxes_path({uri: 'http://example.com'})").to eq(test_routes.inboxes_path(uri: "http://example.com"))
    end

    it "supports nested object null parameters" do
      expectjs("Routes.inboxes_path({hello: {world: null}})").to eq(test_routes.inboxes_path(hello: {world: nil}))
    end
  end

  context "routes globbing" do
    it "is supported as parameters" do
      expectjs("Routes.book_path('thrillers', 1)").to eq(test_routes.book_path("thrillers", 1))
    end

    it "supports routes globbing as single-element array" do
      expectjs("Routes.book_path(['thrillers'], 1)").to eq(test_routes.book_path(["thrillers"], 1))
    end

    it "supports routes globbing as multi-element array" do
      expectjs("Routes.book_path([1, 2, 3], 1)").to eq(test_routes.book_path([1, 2, 3], 1))
    end

    it "supports routes globbing with slash" do
      expectjs("Routes.book_path('a_test/b_test/c_test', 1)").to eq(test_routes.book_path("a_test/b_test/c_test", 1))
    end

    it "supports routes globbing as hash" do
      expectjs("Routes.book_path('a%b', 1)").to eq(test_routes.book_path("a%b", 1))
    end

    it "supports routes globbing as array with optional params" do
      expectjs("Routes.book_path([1, 2, 3, 5], 1, {c: '1'})").to eq(test_routes.book_path([1, 2, 3, 5], 1, {c: "1"}))
    end

    it "supports routes globbing in book_title route as array" do
      expectjs("Routes.book_title_path('john', ['thrillers', 'comedian'])").to eq(test_routes.book_title_path("john", ["thrillers", "comedian"]))
    end

    it "supports routes globbing in book_title route as array with optional params" do
      expectjs("Routes.book_title_path('john', ['thrillers', 'comedian'], {some_key: 'some_value'})").to eq(test_routes.book_title_path("john", ["thrillers", "comedian"], {some_key: "some_value"}))
    end
  end

  context "using optional path fragments" do
    context "including not optional parts" do
      it "includes everything that is not optional" do
        expectjs("Routes.foo_path()").to eq(test_routes.foo_path)
      end
    end

    context "but not including them" do
      it "does not include the optional parts" do
        expectjs("Routes.things_path()").to eq(test_routes.things_path)
        expectjs("Routes.things_path({ q: 'hello' })").to eq(test_routes.things_path(q: "hello"))
      end

      it "treats false as absent optional part" do
        if Rails.version < "7.0"
          pending("https://github.com/rails/rails/issues/42280")
        end
        expectjs("Routes.things_path(false)").to eq(test_routes.things_path(false))
      end

      it "treats false as absent optional part when default is specified" do
        expectjs("Routes.campaigns_path(false)").to eq(test_routes.campaigns_path(false))
      end

      it "does not require the optional parts as arguments" do
        expectjs("Routes.thing_path(null, 5)").to eq(test_routes.thing_path(nil, 5))
      end

      it "treats undefined as non-given optional part" do
        expectjs("Routes.thing_path(5, {optional_id: undefined})").to eq(test_routes.thing_path(5, optional_id: nil))
      end

      it "raises error when passing non-full list of arguments and some query params" do
        expect { evaljs("Routes.thing_path(5, {q: 'hello'})") }
          .to raise_error(/Route missing required keys: id/)
      end

      it "treats null as non-given optional part" do
        expectjs("Routes.thing_path(5, {optional_id: null})").to eq(test_routes.thing_path(5, optional_id: nil))
      end

      it "works when passing required params in options" do
        expectjs("Routes.thing_deep_path({second_required: 1, third_required: 2})").to eq(test_routes.thing_deep_path(second_required: 1, third_required: 2))
      end

      it "skips leading and trailing optional parts" do
        expectjs("Routes.thing_deep_path(1, 2)").to eq(test_routes.thing_deep_path(1, 2))
      end
    end

    context "and including them" do
      it "fails when insufficient arguments are given" do
        expect { evaljs("Routes.thing_deep_path(2)") }.to raise_error(/Route missing required keys: third_required/)
      end

      it "includes the optional parts" do
        expectjs("Routes.things_path({optional_id: 5})").to eq(test_routes.things_path(optional_id: 5))
        expectjs("Routes.things_path(5)").to eq(test_routes.things_path(5))
        expectjs("Routes.thing_deep_path(1, { third_required: 3, second_required: 2 })").to eq(
          test_routes.thing_deep_path(1, third_required: 3, second_required: 2)
        )
        expectjs("Routes.thing_deep_path(1, { third_required: 3, second_required: 2, forth_optional: 4 })").to eq(
          test_routes.thing_deep_path(1, third_required: 3, second_required: 2, forth_optional: 4)
        )
        expectjs("Routes.thing_deep_path(2, { third_required: 3, first_optional: 1 })").to eq(
          test_routes.thing_deep_path(2, third_required: 3, first_optional: 1)
        )
        expectjs("Routes.thing_deep_path(3, { first_optional: 1, second_required: 2 })").to eq(
          test_routes.thing_deep_path(3, first_optional: 1, second_required: 2)
        )
        expectjs("Routes.thing_deep_path(3, { first_optional: 1, second_required: 2, forth_optional: 4 })").to eq(
          test_routes.thing_deep_path(3, first_optional: 1, second_required: 2, forth_optional: 4)
        )
        expectjs("Routes.thing_deep_path(4, { first_optional: 1, second_required: 2, third_required: 3 })").to eq(
          test_routes.thing_deep_path(4, first_optional: 1, second_required: 2, third_required: 3)
        )
        expectjs("Routes.thing_deep_path(2, 3)").to eq(
          test_routes.thing_deep_path(2, 3)
        )
        expectjs("Routes.thing_deep_path(1, 2, { third_required: 3 })").to eq(
          test_routes.thing_deep_path(1, 2, third_required: 3)
        )
        expectjs("Routes.thing_deep_path(1,2, {third_required: 3, q: 'bogdan'})").to eq(
          test_routes.thing_deep_path(1, 2, {third_required: 3, q: "bogdan"})
        )
        expectjs("Routes.thing_deep_path(1, 2, { forth_optional: 4, third_required: 3 })").to eq(
          test_routes.thing_deep_path(1, 2, forth_optional: 4, third_required: 3)
        )
        expectjs("Routes.thing_deep_path(1, 3, { second_required: 2 })").to eq(
          test_routes.thing_deep_path(1, 3, second_required: 2)
        )
        expectjs("Routes.thing_deep_path(1, 4, { second_required: 2, third_required: 3 })").to eq(
          test_routes.thing_deep_path(1, 4, second_required: 2, third_required: 3)
        )
        expectjs("Routes.thing_deep_path(2, 3, { first_optional: 1 })").to eq(
          test_routes.thing_deep_path(2, 3, first_optional: 1)
        )
        expectjs("Routes.thing_deep_path(2, 3, { first_optional: 1, forth_optional: 4 })").to eq(
          test_routes.thing_deep_path(2, 3, first_optional: 1, forth_optional: 4)
        )
        expectjs("Routes.thing_deep_path(2, 4, { first_optional: 1, third_required: 3 })").to eq(
          test_routes.thing_deep_path(2, 4, first_optional: 1, third_required: 3)
        )
        expectjs("Routes.thing_deep_path(3, 4, { first_optional: 1, second_required: 2 })").to eq(
          test_routes.thing_deep_path(3, 4, first_optional: 1, second_required: 2)
        )
        expectjs("Routes.thing_deep_path(1, 2, 3)").to eq(
          test_routes.thing_deep_path(1, 2, 3)
        )
        expectjs("Routes.thing_deep_path(1, 2, 3, { forth_optional: 4 })").to eq(
          test_routes.thing_deep_path(1, 2, 3, forth_optional: 4)
        )
        expectjs("Routes.thing_deep_path(1, 2, 4, { third_required: 3 })").to eq(
          test_routes.thing_deep_path(1, 2, 4, third_required: 3)
        )
        expectjs("Routes.thing_deep_path(1, 3, 4, { second_required: 2 })").to eq(
          test_routes.thing_deep_path(1, 3, 4, second_required: 2)
        )
        expectjs("Routes.thing_deep_path(2, 3, 4, { first_optional: 1 })").to eq(
          test_routes.thing_deep_path(2, 3, 4, first_optional: 1)
        )
        expectjs("Routes.thing_deep_path(1, 2, 3, 4)").to eq(
          test_routes.thing_deep_path(1, 2, 3, 4)
        )
      end

      context "on nested optional parts" do
        if Rails.version <= "5.0.0"
          # this type of routing is deprecated
          it "includes everything that is not optional" do
            expectjs("Routes.classic_path({controller: 'classic', action: 'edit'})").to eq(test_routes.classic_path(controller: :classic, action: :edit))
          end
        end
      end
    end
  end

  context "when wrong parameters given" do
    it "throws Exception if not enough parameters" do
      expect {
        evaljs("Routes.inbox_path()")
      }.to raise_error(js_error_class)
    end

    it "throws Exception if required parameter is null" do
      expect {
        evaljs("Routes.inbox_path(null)")
      }.to raise_error(js_error_class)
    end

    it "throws Exception if required parameter is undefined" do
      expect {
        evaljs("Routes.inbox_path(undefined)")
      }.to raise_error(js_error_class)
    end

    it "throws Exceptions if when there is too many parameters" do
      expect {
        evaljs("Routes.inbox_path(1,2,3)")
      }.to raise_error(js_error_class)
    end
  end

  context "when javascript engine without Array#indexOf is used" do
    before do
      evaljs("Array.prototype.indexOf = null")
    end

    it "stills work correctly" do
      expectjs("Routes.inboxes_path()").to eq(test_routes.inboxes_path)
    end
  end

  context "when arguments are objects" do
    let(:klass) { Struct.new(:id, :to_param) }
    let(:inbox) { klass.new(1, "my") }

    it "throws Exceptions if when pass id with null" do
      expect {
        evaljs("Routes.inbox_path({id: null})")
      }.to raise_error(js_error_class)
    end

    it "throws Exceptions if when pass to_param with null" do
      expect {
        evaljs("Routes.inbox_path({to_param: null})")
      }.to raise_error(js_error_class)
    end

    it "supports 0 as a to_param option" do
      expectjs("Routes.inbox_path({to_param: 0})").to eq(test_routes.inbox_path(Struct.new(:to_param).new("0")))
    end

    it "checks for options special key" do
      expectjs("Routes.inbox_path({id: 7, q: 'hello', _options: true})").to eq(test_routes.inbox_path(id: 7, q: "hello"))
      expect {
        evaljs("Routes.inbox_path({to_param: 7, _options: true})")
      }.to raise_error(js_error_class)
      expectjs("Routes.inbox_message_path(5, {id: 7, q: 'hello', _options: true})").to eq(test_routes.inbox_message_path(5, id: 7, q: "hello"))
    end

    it "supports 0 as an id option" do
      expectjs("Routes.inbox_path({id: 0})").to eq(test_routes.inbox_path(0))
    end

    it "uses id property of the object in path" do
      expectjs("Routes.inbox_path({id: 1})").to eq(test_routes.inbox_path(1))
    end

    it "prefers to_param property over id property" do
      expectjs("Routes.inbox_path({id: 1, to_param: 'my'})").to eq(test_routes.inbox_path(inbox))
    end

    it "calls to_param if it is a function" do
      expectjs("Routes.inbox_path({id: 1, to_param: function(){ return 'my';}})").to eq(test_routes.inbox_path(inbox))
    end

    it "calls id if it is a function" do
      expectjs("Routes.inbox_path({id: function() { return 1;}})").to eq(test_routes.inbox_path(1))
    end

    it "supports options argument" do
      expectjs(
        "Routes.inbox_message_path({id:1, to_param: 'my'}, {id:2}, {custom: true, format: 'json'})"
      ).to eq(test_routes.inbox_message_path(inbox, 2, custom: true, format: "json"))
    end

    it "supports camel case property name" do
      expectjs("Routes.inbox_path({id: 1, toParam: 'my'})").to eq(test_routes.inbox_path(inbox))
    end

    it "supports camel case method name" do
      expectjs("Routes.inbox_path({id: 1, toParam: function(){ return 'my';}})").to eq(test_routes.inbox_path(inbox))
    end

    context "when globbing" do
      it "prefers to_param property over id property" do
        expectjs("Routes.book_path({id: 1, to_param: 'my'}, 1)").to eq(test_routes.book_path(inbox, 1))
      end

      it "calls to_param if it is a function" do
        expectjs("Routes.book_path({id: 1, to_param: function(){ return 'my';}}, 1)").to eq(test_routes.book_path(inbox, 1))
      end

      it "calls id if it is a function" do
        expectjs("Routes.book_path({id: function() { return 'technical';}}, 1)").to eq(test_routes.book_path("technical", 1))
      end

      it "supports options argument" do
        expectjs(
          "Routes.book_path({id:1, to_param: 'my'}, {id:2}, {custom: true, format: 'json'})"
        ).to eq(test_routes.book_path(inbox, 2, custom: true, format: "json"))
      end
    end
  end

  describe "script_name option" do
    it "preceeds the path" do
      expectjs(
        "Routes.inboxes_path({ script_name: '/myapp' })"
      ).to eq(
        test_routes.inboxes_path(script_name: "/myapp")
      )
    end

    it "strips double slash" do
      expectjs(
        "Routes.inboxes_path({ script_name: '/myapp/' })"
      ).to eq(
        test_routes.inboxes_path(script_name: "/myapp/")
      )
    end

    it "preserves no preceding slash" do
      expectjs(
        "Routes.inboxes_path({ script_name: 'myapp' })"
      ).to eq(
        test_routes.inboxes_path(script_name: "myapp")
      )
    end
  end

  describe "bigint parameter" do
    it "works" do
      number = 10**20
      expectjs(
        "Routes.inbox_path(#{number}n)"
      ).to eq(
        test_routes.inbox_path(number)
      )
    end
  end
end
