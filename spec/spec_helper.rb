# encoding: utf-8

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rails/all'
require 'js-routes'
require "v8"
require "cgi"
require "active_support/core_ext/hash/slice"
require 'coffee-script'

def jscontext
  @context ||= V8::Context.new
end

def evaljs(string)
  jscontext.eval(string)
end

def routes
  App.routes.url_helpers
end

def blog_routes
  BlogEngine::Engine.routes.url_helpers
end


module BlogEngine
  class Engine < Rails::Engine
    isolate_namespace BlogEngine
  end

end


class App < Rails::Application
  # Enable the asset pipeline
  config.assets.enabled = true
end

def draw_routes

  BlogEngine::Engine.routes.draw do
    resources :posts
  end
  App.routes.draw do
    resources :inboxes do
      resources :messages do
        resources :attachments
      end
    end

    namespace :admin do
      resources :users
    end

    scope "/returns/:return" do
      resources :objects
    end
    resources :returns

    scope "(/optional/:optional_id)" do
      resources :things
    end

    match "/other_optional/(:optional_id)" => "foo#foo", :as => :foo

    match 'books/*section/:title' => 'books#show', :as => :book
    match 'books/:title/*section' => 'books#show', :as => :book_title

    mount BlogEngine::Engine => "/blog", :as => :blog_app

    get '/no_format' => "foo#foo", :format => false, :as => :no_format

    get '/json_only' => "foo#foo", :format => true, :constraints => {:format => /json/}, :as => :json_only

    get '/привет' => "foo#foo", :as => :hello
  end

end

# prevent warning
Rails.configuration.active_support.deprecation = :log

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

  config.before(:each) do
    evaljs("var window = this;")
    # No need to replace native V8 functions for now
    #jscontext[:cgi] = CGI
    #evaljs("function encodeURIComponent(string) {return cgi.escape(string);}")
    jscontext[:log] = lambda {|arg| puts arg.inspect}
  end
  config.before(:all) do
    # compile all js files begin
    Dir["#{File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))}/**/*.coffee"].each do |coffee|
      File.open(coffee.gsub(/\.coffee$/, ""), 'w') {|f| f.write(CoffeeScript.compile(File.read(coffee))) }
    end
    # compile all js files end
    draw_routes
  end
end
