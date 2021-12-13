require 'spec_helper'

describe JsRoutes, "compatibility with NIL (legacy browser)" do
  let(:generated_js) do
    JsRoutes.generate(
      module_type: nil,
      include: /book|inboxes|inbox_message/,
      **_options
    )
  end

  let(:_options) { {} }
  describe "generated js" do
    subject do
      generated_js
    end

    it "should call route function for each route" do
      is_expected.to include("inboxes_path: __jsr.r(")
    end
    it "should have correct function without arguments signature" do
      is_expected.to include('inboxes_path: __jsr.r({"format":{}}')
    end
    it "should have correct function with arguments signature" do
      is_expected.to include('inbox_message_path: __jsr.r({"inbox_id":{"r":true},"id":{"r":true},"format":{}}')
    end
    it "should have correct function signature with unordered hash" do
      is_expected.to include('inbox_message_attachment_path: __jsr.r({"inbox_id":{"r":true},"message_id":{"r":true},"id":{"r":true},"format":{}}')
    end
  end

  describe "inline generation" do
    let(:_options) { {namespace: nil} }
    before do
      evaljs("const r = #{generated_js}")
    end

    it "should be possible" do
      expect(evaljs("r.inboxes_path()")).to eq(test_routes.inboxes_path())
    end
  end

  describe "namespace option" do
    let(:_options) { {namespace: "PHM"} }
    let(:_presetup) { "" }
    before do
      evaljs("var window = this;")
      evaljs(_presetup)
      evaljs(generated_js)
    end
    it "should use this namespace for routing" do
      expect(evaljs("window.Routes")).to be_nil
      expect(evaljs("window.PHM.inboxes_path")).not_to be_nil
    end

    describe "is nested" do
      context "and defined on client" do
        let(:_presetup) { "window.PHM = {}" }
        let(:_options) { {namespace: "PHM.Routes"} }

        it "should use this namespace for routing" do
          expect(evaljs("PHM.Routes.inboxes_path")).not_to be_nil
        end
      end

      context "but undefined on client" do
        let(:_options) { {namespace: "PHM.Routes"} }

        it "should initialize namespace" do
          expect(evaljs("window.PHM.Routes.inboxes_path")).not_to be_nil
        end
      end

      context "and some parts are defined" do
        let(:_presetup) { "window.PHM = { Utils: {} };" }
        let(:_options) { {namespace: "PHM.Routes"} }

        it "should not overwrite existing parts" do
          expect(evaljs("window.PHM.Utils")).not_to be_nil
          expect(evaljs("window.PHM.Routes.inboxes_path")).not_to be_nil
        end
      end
    end
  end
end

