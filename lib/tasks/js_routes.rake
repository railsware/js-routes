
namespace :less do
  namespace :js do
    desc "Make a js file that will have functions that will return restful routes/urls."
    task :routes => :environment do
      require "jsroutes"

      # Hack for actually load the routes (taken from railties console/app.rb)
      ActionDispatch::Callbacks.new(lambda {}, false)

      JsRoutes.generate!
    end
  end
end
