# JsRoutes
[![Build Status](https://travis-ci.org/railsware/js-routes.png)](https://travis-ci.org/railsware/js-routes)

Generates javascript file that defines all Rails named routes as javascript helpers

## Intallation

Your Rails Gemfile:

``` ruby
gem "js-routes"
```

### Basic Setup (Asset Pipeline)

Require js routes file in `application.js` or other bundle

``` js
/*
= require js-routes
*/
```

Also in order to flush asset pipeline cache sometimes you might need to run:

``` sh
rake tmp:cache:clear
```

This cache is not flushed on server restart in development environment.

**Important:** If routes.js file is not updated after some configuration change you need to run this rake task again.

### Advanced Setup

If you need to customize routes file create initializer, like `config/initializers/jsroutes.rb`:

``` ruby
JsRoutes.setup do |config|
  config.option = value
end
```

Available options:

* `default_url_options` - default parameters to be used to generate url
  * Note that currently only optional parameters (like `:format`) can be defaulted.
  * Example: {:format => "json"}
  * Default: {}
* `exclude` - Array of regexps to exclude from js routes.
  * Note that regexp applied to **named route** not to *URL*
  * Default: []
  * The regexp applies only to the name before the `_path` suffix, eg: you want to match exactly `settings_path`, the regexp should be `/^settings$/`
* `include` - Array of regexps to include in js routes.
  * Note that regexp applied to **named route** not to *URL*
  * Default: []
  * The regexp applies only to the name before the `_path` suffix, eg: you want to match exactly `settings_path`, the regexp should be `/^settings$/`
* `namespace` - global object used to access routes.
  * Supports nested namespace like `MyProject.routes`
  * Default: `Routes`
* `prefix` - String representing a url path to prepend to all paths.
  * Example: `http://yourdomain.com`. This will cause route helpers to generate full path only.
  * Default: blank
* `camel_case` (version >= 0.8.8) - Generate camel case route names.
  * Default: false
* `url_links` (version >= 0.8.9) - Generate additional url links, where url_links value is beginning of url routes (ex: http[s]://example.com).
  * Default: false

You can generate routes files on the application side like this:

``` ruby
JsRoutes.generate!("#{path}/app_routes.js", :namespace => "AppRoutes", :exclude => [/^admin_/, /^api_/])
JsRoutes.generate!("#{path}/adm_routes.js", :namespace => "AdmRoutes", :include => /^admin_/)
JsRoutes.generate!("#{path}/api_routes.js", :namespace => "ApiRoutes", :include => /^api_/, :default_url_options => {:format => "json"})
```

In order to generate javascript to string and manipulate them yourself use:
Like:

``` ruby
routes_js = JsRoutes.generate(options)
```

## Usage

Configuration above will create a nice javascript file with `Routes` object that has all the rails routes available:

``` js
Routes.users_path() // => "/users"
Routes.user_path(1) // => "/users/1"
Routes.user_path(1, {format: 'json'}) // => "/users/1.json"
Routes.new_user_project_path(1, {format: 'json'}) // => "/users/1/projects/new.json"
Routes.user_project_path(1,2, {q: 'hello', custom: true}) // => "/users/1/projects/2?q=hello&custom=true"
Routes.user_project_path(1,2, {hello: ['world', 'mars']}) // => "/users/1/projects/2?hello%5B%5D=world&hello%5B%5D=mars"
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

## What about security?

js-routes itself do not have security holes. It makes URLs
without access protection more reachable by potential attacker.
In order to prevent this use `:exclude` option for sensitive urls like `/admin_/`

## Spork

When using Spork and `Spork.trap_method(Rails::Application::RoutesReloader, :reload!)` you should also do:

``` ruby
Spork.trap_method(JsRoutes, :generate!)
```

## Advantages over alternatives

There are some alternatives available. Most of them has only basic feature and don't reach the level of quality I accept.
Advantages of this one are:

* Rails3 support
* Rich options set
* Support Rails `#to_param` convention for seo optimized paths
* Well tested

#### Thanks to [Contributors](https://github.com/railsware/js-routes/contributors)

#### Have fun
