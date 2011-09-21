$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'js-routes'
require 'rails/all'
require "v8"
require "active_support/core_ext/hash/slice"

def evaljs(string)
  @context ||= V8::Context.new
  @context.eval(string)
end


class App < Rails::Application
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


# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end
