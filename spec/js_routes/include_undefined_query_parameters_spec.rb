require 'spec_helper'

describe "include_undefined_query_parameters migration" do
  let(:deprecator) do
    double("deprecator").tap do |object|
      allow(object).to receive(:warn)
    end
  end

  before do
    allow(JsRoutes::Utils).to receive(:deprecator).and_return(deprecator)
  end

  it "warns and preserves legacy serialization when unset" do
    evaluate_routes_without_default

    expect(deprecator).to have_received(:warn).with(a_string_matching(/include_undefined_query_parameters/))
    expectjs("Routes.config().include_undefined_query_parameters").to eq(true)
    expectjs("Routes.serialize({a: undefined})").to eq({a: nil}.to_query)
  end

  it "does not warn and preserves legacy serialization when explicitly enabled" do
    evaluate_routes(include_undefined_query_parameters: true)

    expect(deprecator).not_to have_received(:warn)
    expectjs("Routes.config().include_undefined_query_parameters").to eq(true)
    expectjs("Routes.serialize({a: undefined})").to eq({a: nil}.to_query)
  end

  it "does not warn and omits undefined object properties when disabled" do
    evaluate_routes(include_undefined_query_parameters: false)

    expect(deprecator).not_to have_received(:warn)
    expectjs("Routes.config().include_undefined_query_parameters").to eq(false)
    expectjs("Routes.serialize({a: undefined})").to eq("")
  end

  it "treats undefined as a non-given optional path part when disabled" do
    evaluate_routes(include_undefined_query_parameters: false)

    expectjs("Routes.thing_path(5, {optional_id: undefined})").to eq(
      test_routes.thing_path(5, :optional_id => nil)
    )
  end

  def evaluate_routes(**options)
    evallib(module_type: nil, namespace: 'Routes', **options)
  end

  def evaluate_routes_without_default
    JsRoutes.configuration.include_undefined_query_parameters = nil

    evaljs(
      JsRoutes.generate(module_type: nil, namespace: 'Routes'),
      filename: 'lib/routes.js'
    )
  end
end
