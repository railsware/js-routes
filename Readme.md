# JsRoutes
[![Build Status](https://travis-ci.org/railsware/js-routes.svg?branch=master)](https://travis-ci.org/railsware/js-routes)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Frailsware%2Fjs-routes.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Frailsware%2Fjs-routes?ref=badge_shield)

Generates javascript file that defines all Rails named routes as javascript helpers

## Intallation

Your Rails Gemfile:

``` ruby
gem "js-routes"
```

## Setup

Run:

```
rake js:routes 
```

Make routes available globally in `app/javascript/packs/application.js`: 

``` javascript
window.Routes = require('routes');
```

Individual routes can be imported using:

``` javascript
import {edit_post_path, new_post_path} from 'routes';
```

**Note**: that this setup requires `rake js:routes` to be run each time routes file is updated.

#### Webpacker + automatic updates

This setup can automatically update your routes without `rake js:routes` being called manually.
It requires [rails-erb-loader](https://github.com/usabilityhub/rails-erb-loader) npm package to work.

Add `erb` loader to webpacker:

```
yarn add rails-erb-loader
rm -f app/javascript/routes.js // delete static file if any
```

Create webpack ERB config `config/webpack/loaders/erb.js`:

``` javascript
module.exports = {
  test: /\.js\.erb$/,
  enforce: 'pre',
  exclude: /node_modules/,
  use: [{
    loader: 'rails-erb-loader',
    options: {
      runner: (/^win/.test(process.platform) ? 'ruby ' : '') + 'bin/rails runner'
    }
  }]
}
```

Enable `erb` extension in `config/webpacker/environment.js`:

```
const erb = require('./loaders/erb')
environment.loaders.append('erb', erb)
```

Create routes file `app/javascript/routes.js.erb`:

``` erb
<%= JsRoutes.generate() %>
```

Use routes wherever you need them `app/javascript/packs/application.js`: 

``` javascript
window.Routes = require('routes.js.erb');
```

#### Sprockets (Deprecated)

If you are using [Sprockets](https://github.com/rails/sprockets-rails) you may configure js-routes in the following way.

Require JsRoutes in `app/assets/javascripts/application.js` or other bundle

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

You can configure JsRoutes in two main ways. Either with an initializer (e.g. `config/initializers/js_routes.rb`):

``` ruby
JsRoutes.setup do |config|
  config.option = value
end
```

Or dynamically in JavaScript, although only [Formatter Options](#formatter-options) are supported (see below)

``` js
Routes.configure({
  option: value
});
Routes.config(); // current config
```

#### Available Options

##### Generator Options

Options to configure JavaScript file generator. These options are only available in Ruby context but not JavaScript.

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
* `file` - a file location where generated routes are stored
  * Default: `app/assets/javascripts/routes.js` if `app/assets/javascripts` directory exists, otherwise `app/javascript/routes.js`.

##### Formatter Options

Options to configure routes formatting. These options are available both in Ruby and JavaScript context.

* `default_url_options` - default parameters used when generating URLs
  * Example: `{format: "json", trailing_slash: true, protocol: "https", subdomain: "api", host: "example.com", port: 3000}`
  * Default: `{}`
* `prefix` - string that will prepend any generated URL. Usually used when app URL root includes a path component.
  * Example: `/rails-app`
  * Default: `Rails.application.config.relative_url_root`
* `serializer` - a JS function that serializes a Javascript Hash object into URL paramters like `{a: 1, b: 2} => "a=1&b=2"`.
  * Default: `nil`. Uses built-in serializer compatible with Rails
  * Example: `jQuery.param` - use jQuery's serializer algorithm. You can attach serialize function from your favorite AJAX framework.
  * Example: `function (object) { ... }` - use completely custom serializer of your application.
* `special_options_key` - a special key that helps JsRoutes to destinguish serialized model from options hash
  * This option exists because JS doesn't provide a difference between an object and a hash
  * Default: `_options`

### Advanced Setup

In case you need multiple route files for different parts of your application, you have to create the files manually.
If your application has an `admin` and an `application` namespace for example:

```
# app/javascript/admin/routes.js.erb
<%= JsRoutes.generate(namespace: "AdminRoutes", include: /admin/) %>
```

```
# app/javascript/customer/routes.js.erb
<%= JsRoutes.generate(namespace: "CustomerRoutes", exclude: /admin/) %>
```

In order to generate the routes JS code to a string:

``` ruby
routes_js = JsRoutes.generate(options)
```

If you want to generate the routes files outside of the asset pipeline, you can use `JsRoutes.generate!`:

``` ruby
path = "app/assets/javascripts"
JsRoutes.generate!("#{path}/app_routes.js", namespace: "AppRoutes", exclude: [/^admin_/, /^api_/])
JsRoutes.generate!("#{path}/adm_routes.js", namespace: "AdmRoutes", include: /^admin_/)
JsRoutes.generate!("#{path}/api_routes.js", namespace: "ApiRoutes", include: /^api_/, default_url_options: {format: "json"})
```

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
