# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'js_routes/version'

Gem::Specification.new do |s|
  s.name = %q{js-routes}
  s.version = JsRoutes::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bogdan Gusiev"]
  s.date = %q{2013-02-13}
  s.description = %q{Generates javascript file that defines all Rails named routes as javascript helpers}
  s.email = %q{agresso@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt"
  ]
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/railsware/js-routes}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.0}
  s.summary = %q{Brings Rails named routes to javascript}

  s.add_runtime_dependency(%q<rails>, [">= 3.2"])
  s.add_development_dependency(%q<rspec>, [">= 2.14.0"])
  s.add_development_dependency(%q<bundler>, [">= 1.1.0"])
  s.add_development_dependency(%q<guard>, [">= 0"])
  s.add_development_dependency(%q<guard-coffeescript>, [">= 0"])
  s.add_development_dependency(%q<appraisal>, [">= 0.5.2"])
  if defined?(JRUBY_VERSION)
    s.add_development_dependency(%q<therubyrhino>, [">= 0"])
  else
    s.add_development_dependency(%q<debugger>, [">= 0"])
    s.add_development_dependency(%q<therubyracer>, [">= 0"])
  end
end

