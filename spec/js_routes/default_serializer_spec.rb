require "spec_helper"

describe JsRoutes, "#serialize" do

  let(:options) do
    {
      module_type: nil,
      namespace: 'Routes',
    }
  end

  before(:each) do
    evallib(**options)
  end

  it "should provide this method" do
    expectjs("Routes.serialize({a: 1, b: [2,3], c: {d: 4, e: 5}, f: ''})").to eq(
      {a: 1, b: [2,3], c: {d: 4, e: 5}, f: ''}.to_query
    )
  end

  it "works with JS suckiness" do
    expectjs(
      [
        "const query = Object.create(null);",
        "query.a = 1;",
        "query.b = 2;",
        "Routes.serialize(query);",
      ].join("\n")
    ).to eq({a:1, b:2}.to_query)
  end

  it "omits undefined object properties by default" do
    expectjs("Routes.serialize({a: undefined})").to eq({}.to_query)
  end

  context "with Rails nil query serialization compatibility" do
    it "serializes null as Rails nil and omits undefined by default" do
      expectjs("Routes.serialize({a: null, b: undefined})").to eq({a: nil}.to_query)
    end
  end

  context "with include_undefined_query_parameters enabled" do
    let(:options) do
      super().merge(include_undefined_query_parameters: true)
    end

    it "serializes undefined object properties as Rails nil" do
      expectjs("Routes.serialize({a: undefined})").to eq({a: nil}.to_query)
    end

    it "serializes undefined and null as Rails nil" do
      expectjs("Routes.serialize({a: null, b: undefined})").to eq({a: nil, b: nil}.to_query)
    end

    it "serializes nested undefined object properties as Rails nil" do
      expectjs("Routes.serialize({a: {b: 1, c: undefined}, d: undefined})").to eq(
        {a: {b: 1, c: nil}, d: nil}.to_query
      )
    end

    it "serializes array object undefined properties as Rails nil" do
      expectjs("Routes.serialize({a: [{b: undefined}, {c: 1}]})").to eq(
        {a: [{b: nil}, {c: 1}]}.to_query
      )
    end

    it "serializes mixed array object undefined properties as Rails nil" do
      expectjs("Routes.serialize({a: [1, {b: undefined}, 2]})").to eq(
        {a: [1, {b: nil}, 2]}.to_query
      )
    end

    it "serializes nested array object undefined properties as Rails nil" do
      expectjs("Routes.serialize({a: [{b: {c: undefined}}, {d: 1}]})").to eq(
        {a: [{b: {c: nil}}, {d: 1}]}.to_query
      )
    end

    it "preserves explicit null and serializes undefined as Rails nil" do
      expectjs("Routes.serialize({a: null, b: {c: null, d: undefined}})").to eq(
        {a: nil, b: {c: nil, d: nil}}.to_query
      )
    end
  end

  context "with include_undefined_query_parameters disabled" do
    let(:options) do
      super().merge(include_undefined_query_parameters: false)
    end

    it "omits top-level undefined object properties" do
      expectjs("Routes.serialize({a: 1, b: undefined})").to eq({a: 1}.to_query)
    end

    it "omits nested undefined object properties" do
      expectjs("Routes.serialize({a: {b: 1, c: undefined}, d: undefined})").to eq(
        {a: {b: 1}}.to_query
      )
    end

    it "serializes array objects with omitted undefined properties like Rails" do
      expectjs("Routes.serialize({a: [{b: undefined}, {c: 1}]})").to eq(
        {a: [{}, {c: 1}]}.to_query
      )
    end

    it "serializes mixed arrays with omitted undefined properties like Rails" do
      expectjs("Routes.serialize({a: [1, {b: undefined}, 2]})").to eq(
        {a: [1, {}, 2]}.to_query
      )
    end

    it "keeps nested undefined array elements serialized as Rails nil" do
      expectjs("Routes.serialize({a: [[undefined], {b: 1}]})").to eq(
        {a: [[nil], {b: 1}]}.to_query
      )
    end

    it "serializes nested objects that become empty inside arrays like Rails" do
      expectjs("Routes.serialize({a: [{b: {c: undefined}}, {d: 1}]})").to eq(
        {a: [{b: {}}, {d: 1}]}.to_query
      )
    end

    it "preserves explicit null as Rails nil" do
      expectjs("Routes.serialize({a: null, b: {c: null, d: undefined}})").to eq(
        {a: nil, b: {c: nil}}.to_query
      )
    end

    it "keeps undefined array elements serialized as Rails nil" do
      expectjs("Routes.serialize({a: [undefined]})").to eq(
        {a: [nil]}.to_query
      )
    end

    context "with Rails nil query serialization compatibility" do
      it "omits undefined and serializes null as Rails nil" do
        expectjs("Routes.serialize({a: null, b: undefined})").to eq({a: nil}.to_query)
      end
    end
  end
end
