## JsRoutes

Generates javascript file that defines all Rails named routes as javascript helpers

### Intallation

Your Rails Gemfile:

``` ruby
gem "js-routes", :require => 'js_routes'
```

Your application initializer, like `config/initializers/jsroutes.rb`:

``` ruby
JsRoutes.generate!({
 #options
})
```

Available options:

* `:file` - the file to generate the routes. Default: 
  * `#{Rails.root}/app/assets/javascripts/routes.js` for Rails >= 3.1
  * `#{Rails.root}/public/javascripts/routes.js` for Rails < 3.1
* `:default_format` - Format to append to urls. Default: blank
* `:exclude` - Array of regexps to exclude from js routes. Default: []
  * Note that regexp applied to **named route** not to *URL*
* `:include` - Array of regexps to include in js routes. Default: []
  * Note that regexp applied to **named route** not to *URL*
* `:namespace` - global object used to access routes. Default: `Routes`
  * Supports nested namespace like `MyProject.routes`
* `:prefix` - String representing a url path to prepend to all paths
  * `Should be specified via :prefix => "/myprefix"`

This is how you can generate separated routes files for different parts of application:

``` ruby
JsRoutes.generate!(:file => "#{path}/app_routes.js", :namespace => "AppRoutes", :exclude => /^admin_/, :default_format => "json")
JsRoutes.generate!(:file => "#{path}/adm_routes.js", :namespace => "AdmRoutes", :include => /^admin_/, :default_format => "json")
```

In order to generate routes to string and manipulate them yourself use:
Like:

``` ruby
routes_js = JsRoutes.generate(options)
```

### Usage

Configuration above will create a nice javascript file with `Routes` object that has all the rails routes available:

``` js
Routes.users_path() // => "/users"
Routes.user_path(1) // => "/users/1"
Routes.user_path(1, {format: 'json'}) // => "/users/1.json"
Routes.new_user_project_path(1, {format: 'json'}) // => "/users/1/projects/new.json"
Routes.user_project_path(1,2, {q: 'hello', custom: true}) // => "/users/1/projects/2?q=hello&custom=true"
```

Using serialized object as route function arguments:

``` js
var google = {id: 1, name: "Google"};
Routes.company_path(google) // => "/companies/1"
var google = {id: 1, name: "Google", to_param: "google"};
Routes.company_path(google) // => "/companies/google"
```

In order to make routes helpers available globally:

``` js
jQuery.extend(window, Routes)
```

### What about security?

js-routes itself do not have security holes. It makes URLs 
without access protection more reachable by potential attacker.
In order to prevent this use `:exclude` option for sensitive urls like `/admin_/`


### Advantages over alternatives

There are some alternatives available. Most of them has only basic feature and don't reach the level of quality I accept. 
Advantages of this one are:

* Rails3 support
* Rich options set
* Support Rails `#to_param` convention for seo optimized paths
* Well tested

#### Have fun 
