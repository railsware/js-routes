# JsRoutes
[![Build Status](https://travis-ci.org/railsware/js-routes.svg?branch=master)](https://travis-ci.org/railsware/js-routes)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Frailsware%2Fjs-routes.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Frailsware%2Fjs-routes?ref=badge_shield)

Generates javascript file that defines all Rails named routes as javascript helpers

## Intallation

Your Rails Gemfile:

``` ruby
gem "js-routes"
```

### Basic Setup

Require JsRoutes in `application.js` or other bundle

``` js
//= require js-routes
```

Also in order to flush asset pipeline cache sometimes you might need to run:

``` sh
rake tmp:cache:clear
```

This cache is not flushed on server restart in development environment.

**Important:** If routes.js file is not updated after some configuration change you need to run this rake task again.

### Configuration

You can configure JsRoutes in two main ways. Either with an initializer (e.g. `config/initializers/jsroutes.rb`):

``` ruby
JsRoutes.setup do |config|
  config.option = value
end
```

Or dynamically in JavaScript, although only "Formatter Options" are supported (see below)

``` js
Routes.configure({
  option: value
});
Routes.config(); // current config
```

#### Available Options

##### Generator Options

Options to configure JavaScript file generator:

* `exclude` - Array of regexps to exclude from routes.
  * Default: `[]`
  * The regexp applies only to the name before the `_path` suffix, eg: you want to match exactly `settings_path`, the regexp should be `/^settings$/`
* `include` - Array of regexps to include in routes.
  * Default: `[]`
  * The regexp applies only to the name before the `_path` suffix, eg: you want to match exactly `settings_path`, the regexp should be `/^settings$/`
* `namespace` - global object used to access routes.
  * Supports nested namespace like `MyProject.routes`
  * Default: `Routes`
* `camel_case` - Generate camel case route names.
  * Default: `false`
* `url_links` - Generate `*_url` helpers (in addition to the default `*_path` helpers).
  * Example: `true`
  * Default: `false`
  * Note: generated URLs will first use the protocol, host, and port options specified in the route definition. Otherwise, the URL will be based on the option specified in the `default_url_options` config. If no default option has been set, then the URL will fallback to the current URL based on `window.location`.
* `compact` - Remove `_path` suffix in path routes(`*_url` routes stay untouched if they were enabled)
  * Default: `false`
  * Sample route call when option is set to true: Routes.users() => `/users`
* `application` - a key to specify which rails engine you want to generate routes too.
  * This option allows to only generate routes for a specific rails engine, that is mounted into routes instead of all Rails app routes
  * Default: `Rails.application`

##### Formatter Options

Options to configure routes formatting:

* `default_url_options` - default parameters used when generating URLs
  * Option is configurable at JS level with `Routes.configure()`
  * Example: `{format: "json", trailing_slash: true, protocol: "https", subdomain: "api", host: "example.com", port: 3000}`
  * Default: `{}`
* `prefix` - String representing a url path to prepend to all paths.
  * Option is configurable at JS level with `Routes.configure()`
  * Example: `http://yourdomain.com`. This will cause route helpers to generate full path only.
  * Default: `Rails.application.config.relative_url_root`
* `serializer` - a JS function that serializes a Javascript Hash object into URL paramters like `{a: 1, b: 2} => "a=1&b=2"`.
  * Default: `nil`. Uses built-in serializer compatible with Rails
  * Option is configurable at JS level with `Routes.configure()`
  * Example: `jQuery.param` - use jQuery's serializer algorithm. You can attach serialize function from your favorite AJAX framework.
  * Example: `function (object) { ... }` - use completely custom serializer of your application.
* `special_options_key` - a special key that helps JsRoutes to destinguish serialized model from options hash
  * This option exists because JS doesn't provide a difference between an object and a hash
  * Option is configurable at JS level with `Routes.configure()`
  * Default: `_options`

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

In order to generate the routes JS code to a string:

```ruby
routes_js = JsRoutes.generate(options)
```

If you want to generate the routes files outside of the asset pipeline, you can use `JsRoutes.generate!`:

``` ruby
path = "app/assets/javascripts"
JsRoutes.generate!("#{path}/app_routes.js", namespace: "AppRoutes", exclude: [/^admin_/, /^api_/])
JsRoutes.generate!("#{path}/adm_routes.js", namespace: "AdmRoutes", include: /^admin_/)
JsRoutes.generate!("#{path}/api_routes.js", namespace: "ApiRoutes", include: /^api_/, default_url_options: {format: "json"})
```

### Rails relative URL root

If you've installed your application in a sub-path or sub-URI of your server instead of at the root, you need to set the `RAILS_RELATIVE_URL_ROOT` environment variable to the correct path prefix for your application when you precompile assets. Eg., if your application's base URL is "https://appl.example.com/Application1", the command to precompile assets would be:
```
RAILS_RELATIVE_URL_ROOT=/Application1 RAILS_ENV=production bundle exec rake assets:precompile
```
The environment variable is only needed for precompilation of assets, at any other time (eg. when assets are compiled on-the-fly as in the development environment) Rails will set the relative URL root correctly on it's own.


## Usage

Configuration above will create a nice javascript file with `Routes` object that has all the rails routes available:

``` js
Routes.users_path() // => "/users"
Routes.user_path(1) // => "/users/1"
Routes.user_path(1, {format: 'json'}) // => "/users/1.json"
Routes.user_path(1, {anchor: 'profile'}) // => "/users/1#profile"
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

## Get spec of routes and required params

Possible to get `spec` of route by function `toString`:

```js
Routes.users_path.toString() // => "/users(.:format)"
Routes.user_path.toString() // => "/users/:id(.:format)"
```

This function allow to get the same `spec` for route, if you will get string representation of the route function:

```js
'' + Routes.users_path // => "/users(.:format)", a string representation of the object
'' + Routes.user_path // => "/users/:id(.:format)"
```

Route function also contain inside attribute `required_params` required param names as array:

```js
Routes.users_path.required_params // => []
Routes.user_path.required_params // => ['id']
```


## Rails Compatibility

JsRoutes tries to replicate the Rails routing API as closely as possible. If you find any incompatibilities (outside of what is described below), please [open an issue](https://github.com/railsware/js-routes/issues/new).

### Object and Hash distinction issue

Sometimes the destinction between JS Hash and Object can not be found by JsRoutes.
In this case you would need to pass a special key to help:

``` js
Routes.company_project_path({company_id: 1, id: 2}) // => Not enough parameters
Routes.company_project_path({company_id: 1, id: 2, _options: true}) // => "/companies/1/projects/2"
```


## What about security?

JsRoutes itself does not have security holes. It makes URLs
without access protection more reachable by potential attacker.
In order to prevent this use `:exclude` option for sensitive urls like `/admin_/`

## JsRoutes and Heroku

When using this setup on Heroku, it is impossible to use the asset pipeline. You should use the "Very Advanced Setup" schema in this case.

For example create routes.js.erb in assets folder with needed content:

``` erb
<%= JsRoutes.generate(options) %>
```

This should just work.

## Advantages over alternatives

There are some alternatives available. Most of them has only basic feature and don't reach the level of quality I accept.
Advantages of this one are:

* Rails 4,5,6 support
* Rich options set
* Full rails compatibility
* Support Rails `#to_param` convention for seo optimized paths
* Well tested

#### Thanks to [contributors](https://github.com/railsware/js-routes/contributors)

#### Have fun


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Frailsware%2Fjs-routes.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Frailsware%2Fjs-routes?ref=badge_large)
