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
  * Note that currently only optional parameters (like `:format` or `:trailing_slash`) can be defaulted.
  * Example: {:format => "json", :trailing_slash => true}
  * Default: {}
* `exclude` - Array of regexps to exclude from js routes.
  * Default: []
  * The regexp applies only to the name before the `_path` suffix, eg: you want to match exactly `settings_path`, the regexp should be `/^settings$/`
* `include` - Array of regexps to include in js routes.
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
* `url_links` (version >= 0.8.9) - Generate `*_url` links (in addition to default `*_path`), where url_links value is beginning of url routes
  * Example: http[s]://example.com
  * Default: false
* `compact` (version > 0.9.9) - Remove `_path` suffix in path routes(`*_url` routes stay untouched if they were enabled)
  * Default: false
  * Sample route call when option is set to true: Routes.users() => `/users`

### Very Advanced Setup

In case you need multiple route files for different parts of your application, you have to create the files manually.
If your application has an `admin` and an `application` namespace for example:

```
# app/assets/javascripts/admin/routes.js.erb
<%= JsRoutes.generate(namespace: "AdminRoutes", include: /admin/) %>

# app/assets/javascripts/admin.js.coffee
#= require admin/routes
```

```
# app/assets/javascripts/application/routes.js.erb
<%= JsRoutes.generate(namespace: "AppRoutes", exclude: /admin/) %>

# app/assets/javascripts/application.js.coffee
#= require application/routes
```

In order to generate the routes to a string:

```ruby
routes_js = JsRoutes.generate(options)
```

If you want to generate the routes files outside of the asset pipeline, you can use `JsRoutes.generate!`:

``` ruby
path = "app/assets/javascripts"
JsRoutes.generate!("#{path}/app_routes.js", :namespace => "AppRoutes", :exclude => [/^admin_/, /^api_/])
JsRoutes.generate!("#{path}/adm_routes.js", :namespace => "AdmRoutes", :include => /^admin_/)
JsRoutes.generate!("#{path}/api_routes.js", :namespace => "ApiRoutes", :include => /^api_/, :default_url_options => {:format => "json"})
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

## Configuring in javascript

Sometimes there's need to configure some options per client connection (eg. per current user's ID).
You can do that with JavaScript's `Routes.configure()` function:

``` js
Routes.configure({prefix: '/MY-USER-UID'});
// wil result in:
Routes.articles_path()
>> "/MY-USER-ID/articles"
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

## JS-Routes and heroku

Heroku environment has a specific problems with setup. It is impossible to use asset pipeline in this environment. You should use "Very Advanced Setup" schema in this case.

For example create routes.js.erb in assets folder with needed content:

``` erb
<%= JsRoutes.generate({ options }) %>
```

This should just work.

## Advantages over alternatives

There are some alternatives available. Most of them has only basic feature and don't reach the level of quality I accept.
Advantages of this one are:

* Rails3 & Rails4 support
* Rich options set
* Support Rails `#to_param` convention for seo optimized paths
* Well tested

#### Thanks to [Contributors](https://github.com/railsware/js-routes/contributors)

#### Have fun
