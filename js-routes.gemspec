lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "js_routes/version"

Gem::Specification.new do |s|
  version = JsRoutes::VERSION
  s.name = "js-routes"
  s.version = version

  s.authors = ["Bogdan Gusiev"]
  s.description = "Exposes all Rails Routes URL helpers as javascript module"
  s.email = "agresso@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt"
  ]
  s.required_ruby_version = ">= 2.4.0"
  s.files = Dir[
    "app/**/*",
    "lib/**/*",
    "CHANGELOG.md",
    "LICENSE.txt",
    "Readme.md"
  ]
  s.homepage = "http://github.com/railsware/js-routes"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.summary = "Brings Rails named routes to javascript"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/railsware/js-routes/issues",
    "changelog_uri" => "https://github.com/railsware/js-routes/blob/v#{version}/CHANGELOG.md",
    "documentation_uri" => "https://github.com/railsware/js-routes",
    "source_code_uri" => "https://github.com/railsware/js-routes/tree/v#{version}",
    "rubygems_mfa_required" => "true",
    "github_repo" => "ssh://github.com/railsware/js-routes"
  }

  s.add_runtime_dependency("railties", [">= 5"])
  s.add_runtime_dependency("sorbet-runtime")

  s.add_development_dependency("sprockets-rails")
  s.add_development_dependency("rspec", [">= 3.10.0"])
  s.add_development_dependency("bundler", [">= 2.2.25"])
  s.add_development_dependency("appraisal", [">= 0.5.2"])
  if defined?(JRUBY_VERSION)
    s.add_development_dependency("therubyrhino", [">= 2.0.4"])
  else
    s.add_development_dependency("mini_racer", [">= 0.4.0"])
  end
end
