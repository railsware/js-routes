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

  it "warns and emits legacy runtime config when unset" do
    evaljs(
      JsRoutes.generate(module_type: nil, namespace: 'Routes', include_undefined_query_parameters: nil),
      filename: 'lib/routes.js'
    )

    expect(deprecator).to have_received(:warn).with(
      a_string_matching(/JsRoutes\.setup \{ \|c\| c\.include_undefined_query_parameters = false \}/)
    )
    expectjs("Routes.config().include_undefined_query_parameters").to eq(true)
  end

  it "does not warn and emits enabled runtime config when explicitly enabled" do
    evaluate_routes(include_undefined_query_parameters: true)

    expect(deprecator).not_to have_received(:warn)
    expectjs("Routes.config().include_undefined_query_parameters").to eq(true)
  end

  it "does not warn and emits disabled runtime config when disabled" do
    evaluate_routes(include_undefined_query_parameters: false)

    expect(deprecator).not_to have_received(:warn)
    expectjs("Routes.config().include_undefined_query_parameters").to eq(false)
  end

  def evaluate_routes(**options)
    evallib(module_type: nil, namespace: 'Routes', **options)
  end
end
