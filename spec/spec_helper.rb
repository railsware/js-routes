# encoding: utf-8

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rails/all'
require 'js-routes'
require 'active_support/core_ext/hash/slice'

unless ENV['TRAVIS_CI']
  code = system("yarn build")
  unless code
    exit(1)
  end
end


if defined?(JRUBY_VERSION)
  require 'rhino'
  JS_LIB_CLASS = Rhino
else
  require 'mini_racer'
  JS_LIB_CLASS = MiniRacer
end

def jscontext(force = false)
  if force
    @jscontext = JS_LIB_CLASS::Context.new
  else
    @jscontext ||= JS_LIB_CLASS::Context.new
  end
end

def js_error_class
  if defined?(JRUBY_VERSION)
    JS_LIB_CLASS::JSError
  else
    JS_LIB_CLASS::Error
  end
end

def evaljs(string, force: false, filename: 'context.js')
  jscontext(force).eval(string, filename: filename)
rescue MiniRacer::ParseError => e
  message = e.message
  _, _, line, _ = message.split(':')
  code = line && string.split("\n")[line.to_i-1]
  raise "#{message}. Code: #{code.strip}";
rescue MiniRacer::RuntimeError => e
  raise e
end

def test_routes
  ::App.routes.url_helpers
end

def blog_routes
  BlogEngine::Engine.routes.url_helpers
end

def planner_routes
  Planner::Engine.routes.url_helpers
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular "budgie", "budgies"
end


module Planner
  class Engine < Rails::Engine
    isolate_namespace Planner
  end
end

module BlogEngine
  class Engine < Rails::Engine
    isolate_namespace BlogEngine
  end

end


class ::App < Rails::Application
  # Enable the asset pipeline
  config.assets.enabled = true
  # initialize_on_precompile
  config.assets.initialize_on_precompile = true
  config.paths['config/routes.rb'] << 'spec/config/routes.rb'
  config.root = File.expand_path('../dummy', __FILE__)
end


# prevent warning
Rails.configuration.active_support.deprecation = :log

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    draw_routes
  end

  config.before :each do
    evaljs("var window = this;", {force: true})

    log = proc do |*values|
      puts values.map(&:inspect).join(", ")
    end
    if defined?(JRUBY_VERSION)
      jscontext[:"console.log"] = lambda do |context, *values|
        log(*values)
      end
    else
      jscontext.attach("console.log", log)
    end
  end
end
