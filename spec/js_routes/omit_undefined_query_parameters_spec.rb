require 'spec_helper'

describe "omit_undefined_query_parameters migration" do
  let(:deprecator) do
    double("deprecator").tap do |object|
      allow(object).to receive(:warn)
    end
  end

  before do
    allow(JsRoutes::Utils).to receive(:deprecator).and_return(deprecator)
  end

  it "warns and preserves legacy serialization when unset" do
    evaluate_routes

    expect(deprecator).to have_received(:warn).with(a_string_matching(/omit_undefined_query_parameters/))
    expectjs("Routes.config().omit_undefined_query_parameters").to be_nil
    expectjs("Routes.serialize({a: undefined})").to eq(rails_nil_query_parameter("a"))
  end

  it "does not warn and preserves legacy serialization when explicitly disabled" do
    evaluate_routes(omit_undefined_query_parameters: false)

    expect(deprecator).not_to have_received(:warn)
    expectjs("Routes.config().omit_undefined_query_parameters").to eq(false)
    expectjs("Routes.serialize({a: undefined})").to eq(rails_nil_query_parameter("a"))
  end

  it "does not warn and omits undefined object properties when enabled" do
    evaluate_routes(omit_undefined_query_parameters: true)

    expect(deprecator).not_to have_received(:warn)
    expectjs("Routes.config().omit_undefined_query_parameters").to eq(true)
    expectjs("Routes.serialize({a: undefined})").to eq("")
  end

  def evaluate_routes(**options)
    evallib(module_type: nil, namespace: 'Routes', **options)
  end

  def rails_nil_query_parameter(key)
    Gem::Version.new(Rails.version) < Gem::Version.new("8.1.0") ? "#{key}=" : key
  end
end
