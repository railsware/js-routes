$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rails/all'
require 'js-routes'
require "v8"
require "cgi"
require "active_support/core_ext/hash/slice"

def jscontext
  @context ||= V8::Context.new
end

def evaljs(string)
  jscontext.eval(string)
end





class App < Rails::Application
  # Enable the asset pipeline
  config.assets.enabled = true

  self.routes.draw do 
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
    jscontext[:cgi] = CGI
    evaljs("function encodeURIComponent(string) {return cgi.escape(string);}")
  end
end
