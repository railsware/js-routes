
require "active_support/core_ext/string/strip"
require "fileutils"
require "open3"
require "spec_helper"

describe JsRoutes, "compatibility with DTS"  do

  let(:extra_options) do
    {}
  end

  let(:options) do
    {
      module_type: 'DTS',
      include: [/^inboxes$/, /^inbox_message_attachment$/],
      **extra_options
    }
  end

  let(:generated_js) do
    JsRoutes.generate(
      module_type: 'DTS',
      include: [/^inboxes$/, /^inbox_message_attachment$/],
      **extra_options
    )
  end

  context "when file is generated" do
    let(:extra_options) do
      { banner: nil }
    end

    let(:dir_name) do
       File.expand_path(__dir__ + "/dts")
    end

    let(:file_name) do
      dir_name + "/routes.spec.d.ts"
    end

    before do
      FileUtils.mkdir_p(dir_name)
      File.write(file_name, generated_js)
    end

    it "has no compile errors", :slow do
      command = "yarn tsc --strict --noEmit -p spec/tsconfig.json"
      stdout, stderr, status = Open3.capture3(command)
      expect(stderr).to eq("")
      expect(stdout).to eq("")
      expect(status).to eq(0)
    end
  end

  context "when camel case is enabled" do
    let(:extra_options) { {camel_case: true} }

    it "camelizes route name and arguments" do

      expect(generated_js).to include(<<-DOC.rstrip)
/**
 * Generates rails route to
 * /inboxes/:inbox_id/messages/:message_id/attachments/:id
 * @param {any} inboxId
 * @param {any} messageId
 * @param {any} id
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inboxMessageAttachmentPath: ((
  inboxId: RequiredRouteParameter,
  messageId: RequiredRouteParameter,
  id: RequiredRouteParameter,
  options?: RouteOptions
) => string) & RouteHelperExtras;
DOC
    end
  end

  context "when optional_definition_params specified" do
    let(:extra_options) { { optional_definition_params: true } }

    it "makes all route params optional" do
      expect(generated_js).to include(<<~JS.rstrip)
        export const inbox_message_attachment_path: ((
          inbox_id?: RequiredRouteParameter,
          message_id?: RequiredRouteParameter,
          id?: RequiredRouteParameter,
          options?: RouteOptions
        ) => string) & RouteHelperExtras;
      JS
    end
  end

  it "exports route helpers" do
    expect(generated_js).to include(<<-DOC.rstrip)
/**
 * Generates rails route to
 * /inboxes(.:format)
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inboxes_path: ((
  options?: {format?: OptionalRouteParameter} & RouteOptions
) => string) & RouteHelperExtras;
DOC
    expect(generated_js).to include(<<-DOC.rstrip)
/**
 * Generates rails route to
 * /inboxes/:inbox_id/messages/:message_id/attachments/:id
 * @param {any} inbox_id
 * @param {any} message_id
 * @param {any} id
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inbox_message_attachment_path: ((
  inbox_id: RequiredRouteParameter,
  message_id: RequiredRouteParameter,
  id: RequiredRouteParameter,
  options?: RouteOptions
) => string) & RouteHelperExtras
DOC
  end

  it "exports utility methods" do
    expect(generated_js).to include("export const serialize: RouterExposedMethods['serialize'];")
  end

  it "prevents all types from automatic export" do
    expect(generated_js).to include("export {};")
  end

  describe "compiled javascript asset" do
    subject { ERB.new(File.read("app/assets/javascripts/js-routes.js.erb")).result(binding) }
    it "should have js routes code" do
      is_expected.to include("export const inbox_message_path = /*#__PURE__*/ __jsr.r(")
    end
  end

  describe ".definitions" do
    let(:extra_options) { { module_type: 'ESM' } }

    it "uses DTS module automatically" do
      generated_js = JsRoutes.definitions(**options)
      expect(generated_js).to include('export {};')
    end
  end
end
