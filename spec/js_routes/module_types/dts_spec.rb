
require "active_support/core_ext/string/strip"
require "fileutils"
require "open3"
require "spec_helper"

describe JsRoutes, "compatibility with DTS"  do

  OPTIONS = {module_type: 'DTS', include: [/^inboxes$/, /^inbox_message_attachment$/]}
  let(:extra_options) do
    {}
  end

  let(:generated_js) do
    JsRoutes.generate({**OPTIONS, **extra_options})
  end

  context "when file is generated" do
    let(:dir_name) do
       File.expand_path(__dir__ + "/../../../tmp")
    end

    let(:file_name) do
      dir_name + "/routes.d.ts"
    end

    before do
      FileUtils.mkdir_p(dir_name)
      File.write(file_name, generated_js)
    end

    it "has no compile errors" do
      command = "tsc --noEmit #{file_name} --out /dev/stdout"
      _, stdout, stderr = Open3.popen3(command)
      expect(stderr.read).to eq("")
      expect(stdout.read).to eq("")
    end

    context "when camel case is enabled" do

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
export const inboxes_path: (
  options?: RouteOptions
) => string;
DOC
    expect(generated_js).to include(<<-DOC.rstrip)
/**
 * Generates rails route to
 * /inboxes/:inbox_id/messages/:message_id/attachments/:id(.:format)
 * @param {any} inbox_id
 * @param {any} message_id
 * @param {any} id
 * @param {object | undefined} options
 * @returns {string} route path
 */
export const inbox_message_attachment_path: (
  inbox_id: unknown,
  message_id: unknown,
  id: unknown,
  options?: RouteOptions
) => string
DOC
  end

  it "exports utility methods" do
    expect(generated_js).to include("export const serialize: RouterExposedMethods['serialize'];")
  end

  # it "defines utility methods" do
    # expect(evaljs("serialize({a: 1, b: 2})")).to eq({a: 1, b: 2}.to_param)
  # end

  describe "compiled javascript asset" do
    subject { ERB.new(File.read("app/assets/javascripts/js-routes.js.erb")).result(binding) }
    it "should have js routes code" do
      is_expected.to include("export const inbox_message_path = __jsr.r(")
    end
  end
end
