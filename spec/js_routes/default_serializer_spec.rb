require "spec_helper"

describe JsRoutes, "#serialize" do

  let(:options) do
    {
      module_type: nil,
      namespace: 'Routes',
    }
  end

  before(:each) do
    JsRoutes::Utils.deprecator.silence do
      evallib(**options)
    end
  end

  it "should provide this method" do
    expectjs("Routes.serialize({a: 1, b: [2,3], c: {d: 4, e: 5}, f: ''})").to eq(
      "a=1&b%5B%5D=2&b%5B%5D=3&c%5Bd%5D=4&c%5Be%5D=5&f="
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
    ).to eq("a=1&b=2")
  end

  it "serializes undefined object properties as Rails nil by default" do
    expectjs("Routes.serialize({a: undefined})").to eq(rails_nil_query_parameter("a"))
  end

  context "with Rails nil query serialization compatibility" do
    it "serializes undefined and null as Rails nil by default with deprecated nil behavior" do
      evaluate_routes_for(rails_version: "8.0.0")

      expectjs("Routes.serialize({a: null, b: undefined})").to eq("a=&b=")
    end

    it "serializes undefined and null as Rails nil by default with bare-key nil behavior" do
      evaluate_routes_for(rails_version: "8.1.0")

      expectjs("Routes.serialize({a: null, b: undefined})").to eq("a&b")
    end
  end

  context "with omit_undefined_query_parameters disabled" do
    let(:options) do
      super().merge(omit_undefined_query_parameters: false)
    end

    it "serializes undefined object properties as Rails nil" do
      expectjs("Routes.serialize({a: undefined})").to eq(rails_nil_query_parameter("a"))
    end
  end

  context "with omit_undefined_query_parameters enabled" do
    let(:options) do
      super().merge(omit_undefined_query_parameters: true)
    end

    it "omits top-level undefined object properties" do
      expectjs("Routes.serialize({a: 1, b: undefined})").to eq("a=1")
    end

    it "omits nested undefined object properties" do
      expectjs("Routes.serialize({a: {b: 1, c: undefined}, d: undefined})").to eq("a%5Bb%5D=1")
    end

    it "preserves explicit null as Rails nil" do
      expectjs("Routes.serialize({a: null, b: {c: null, d: undefined}})").to eq(
        [
          rails_nil_query_parameter("a"),
          rails_nil_query_parameter("b%5Bc%5D"),
        ].join("&")
      )
    end

    it "keeps undefined array elements serialized as Rails nil" do
      expectjs("Routes.serialize({a: [undefined]})").to eq(
        rails_nil_query_parameter("a%5B%5D")
      )
    end

    context "with Rails nil query serialization compatibility" do
      it "omits undefined and serializes null with deprecated nil behavior" do
        evaluate_routes_for(rails_version: "8.0.0")

        expectjs("Routes.serialize({a: null, b: undefined})").to eq("a=")
      end

      it "omits undefined and serializes null with bare-key nil behavior" do
        evaluate_routes_for(rails_version: "8.1.0")

        expectjs("Routes.serialize({a: null, b: undefined})").to eq("a")
      end
    end
  end

  def evaluate_routes_for(rails_version:)
    allow(Rails).to receive(:version).and_return(rails_version)
    JsRoutes::Utils.deprecator.silence do
      evallib(**options)
    end
  end

  def rails_nil_query_parameter(key)
    Gem::Version.new(Rails.version) < Gem::Version.new("8.1.0") ? "#{key}=" : key
  end
end
