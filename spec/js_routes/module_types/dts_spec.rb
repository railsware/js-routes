require "active_support/core_ext/string/strip"
require "fileutils"
require "open3"
require "spec_helper"

describe JsRoutes, "compatibility with DTS" do
  let(:extra_options) do
    {}
  end

  let(:options) do
    {
      module_type: "DTS",
      include: [/^inboxes$/, /^inbox_message_attachment$/],
      **extra_options
    }
  end

  let(:generated_js) do
    described_class.generate(
      module_type: "DTS",
      include: [/^inboxes$/, /^inbox_message_attachment$/],
      **extra_options
    )
  end

  context "when file is generated" do
    let(:extra_options) do
      {banner: nil}
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
      fail(stderr) unless stderr.empty?
      fail(stdout) unless stdout.empty?
      expect(status).to eq(0)
    end
  end

  context "when camel case is enabled" do
    let(:extra_options) { {camel_case: true} }

    it "camelizes route name and arguments" do
      expect(generated_js).to include(<<~DOC.rstrip)
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

  context "when compact is enabled" do
    let(:extra_options) { {compact: true} }

    it "omits _path suffix from route names" do
      expect(generated_js).to include("export const inboxes:")
      expect(generated_js).to include("export const inbox_message_attachment:")
      expect(generated_js).not_to include("export const inboxes_path:")
      expect(generated_js).not_to include("export const inbox_message_attachment_path:")
    end

    it "falls back to _path suffix when compact name is a JS reserved word" do
      js = described_class.generate(module_type: "DTS", compact: true, include: /\Areturn\z/)
      expect(js).to include("export const return_path:")
      expect(js).not_to include("export const return:")
    end
  end

  context "when url_links is enabled" do
    let(:extra_options) { {url_links: true} }

    it "generates both _path and _url variants" do
      expect(generated_js).to include("export const inboxes_path:")
      expect(generated_js).to include("export const inboxes_url:")
      expect(generated_js).to include("export const inbox_message_attachment_path:")
      expect(generated_js).to include("export const inbox_message_attachment_url:")
    end
  end

  context "when optional_definition_params specified" do
    let(:extra_options) { {optional_definition_params: true} }

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
    expect(generated_js).to include(<<~DOC.rstrip)
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
    expect(generated_js).to include(<<~DOC.rstrip)
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

  context "when route parameter matches JavaScript keyword" do
    let(:extra_options) { {include: /\Aobject\z/} }

    it "has _ suffix" do
      expect(generated_js).to include("return_: RequiredRouteParameter")
      expect(generated_js).not_to match(/\breturn: RequiredRouteParameter/)
    end
  end

  it "exports utility methods" do
    expect(generated_js).to include("export const serialize: RouterExposedMethods['serialize'];")
  end

  it "prevents all types from automatic export" do
    expect(generated_js).to include("export {};")
  end

  describe "compiled javascript asset" do
    subject { ERB.new(File.read("app/assets/javascripts/js-routes.js.erb")).result(binding) }

    it "has js routes code" do
      expect(subject).to include("export const inbox_message_path = /*#__PURE__*/ __route(")
    end
  end

  describe ".definitions" do
    let(:extra_options) { {module_type: "ESM"} }

    it "uses DTS module automatically" do
      generated_js = described_class.definitions(**options)
      expect(generated_js).to include("export {};")
    end
  end
end
