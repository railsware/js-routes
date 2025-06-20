# JsRoutes

[![CI](https://github.com/railsware/js-routes/actions/workflows/ci.yml/badge.svg)](https://github.com/railsware/js-routes/actions/workflows/ci.yml)

<img src="/logo.webp" alt="Logo" width="200" height="200">

Generates javascript file that defines all Rails named routes as javascript helpers:

``` js
import { root_path, api_user_path } from './routes';

root_path() # => /
api_user_path(25, include_profile: true, format: 'json') // => /api/users/25.json?include_profile=true
```

[More Examples](#usage)

## Intallation

Your Rails Gemfile:

``` ruby
gem "js-routes"
```

## Setup

There are several possible ways to setup JsRoutes:

1. [Quick and easy](#quick-start) - Recommended
  * Uses Rack Middleware to automatically update routes locally
  * Automatically generates routes files on javascript build
  * Works great for a simple Rails application
2. [Advanced Setup](#advanced-setup)
  * Allows very custom setups
  * Automatic updates need to be customized
3. [Webpacker ERB Loader](#webpacker) - Legacy
  * Requires ESM module system (the default)
  * Doesn't support typescript definitions
4. [Sprockets](#sprockets) - Legacy
  * Deprecated and not recommended for modern apps

<div id="quick-start"></div>

### Quick Start

Setup [Rack Middleware](https://guides.rubyonrails.org/rails_on_rack.html#action-dispatcher-middleware-stack)
to automatically generate and maintain `routes.js` file and corresponding
[Typescript definitions](https://www.typescriptlang.org/docs/handbook/declaration-files/templates/module-d-ts.html) `routes.d.ts`:

#### Use a Generator

Run a command:

``` sh
rails generate js_routes:middleware
```

#### Setup Manually

Add the following to `config/environments/development.rb`:

``` ruby
  config.middleware.use(JsRoutes::Middleware)
```

Use it in any JS file:

``` javascript
import {post_path} from '../routes';

alert(post_path(1))
```

Upgrade js building process to update js-routes files in `Rakefile`:

``` ruby
task "javascript:build" => "js:routes"
# For setups without jsbundling-rails
task "assets:precompile" => "js:routes"
```

Add js-routes files to `.gitignore`:

```
/app/javascript/routes.js
/app/javascript/routes.d.ts
```

<div id="webpack"></div>

### Webpacker ERB loader

**IMPORTANT**: the setup doesn't support IDE autocompletion with [Typescript](https://www.typescriptlang.org/docs/handbook/declaration-files/templates/module-d-ts.html)

#### Use a Generator

Run a command:

``` sh
./bin/rails generate js_routes:webpacker
```

#### Setup manually

The routes files can be automatically updated  without `rake` task being called manually.
It requires [rails-erb-loader](https://github.com/usabilityhub/rails-erb-loader) npm package to work.

Add `erb` loader to webpacker:

``` sh
yarn add rails-erb-loader
rm -f app/javascript/routes.js # delete static file if any
```

Create webpack ERB config `config/webpack/loaders/erb.js`:

``` javascript
module.exports = {
  rules: [
    {
      test: /\.erb$/,
      enforce: "pre",
      loader: "rails-erb-loader",
    },
  ],
};
```

Enable `erb` extension in `config/webpack/environment.js`:

``` javascript
const erb = require('./loaders/erb')
environment.loaders.append('erb', erb)
```

Create routes file `app/javascript/routes.js.erb`:

``` erb
<%= JsRoutes.generate() %>
```

Use routes wherever you need them:

``` javascript
import {post_path} from 'routes.js.erb';

alert(post_path(2));
```

<div id="advanced-setup"></div>

### Advanced Setup

In case you need multiple route files for different parts of your application, there are low level methods:

``` ruby
# Returns a routes file as a string
JsRoutes.generate(options)
# Writes routes to specific file location
JsRoutes.generate!(file_name, options)
# Writes Typescript definitions file for routes
JsRoutes.definitions!(file_name, options)
```

They can also be used in ERB context

``` erb
<script>
    var AdminRoutes = <%= JsRoutes.generate(
      include: /admin/, module_type: nil, namespace: nil
    ) %>;
</script>
```

Routes can be returns via API:

``` ruby
class Api::RoutesController < Api::BaseController
  def index
    options = {
      include: /\Aapi_/,
      default_url_options: { format: 'json' },
    }
    render json: {
      routes: {
        source: JsRoutes.generate(options),
        definitions: JsRoutes.definitions(options),
      }
    }
  end
end

```

Default auto-update middleware for development
doesn't support configuration out of the box,
but it can be extended through inheritence:

``` ruby
class AdvancedJsRoutesMiddleware < JsRoutes::Middleware
  def regenerate
    path = Rails.root.join("app/javascript")

    JsRoutes.generate!(
      "#{path}/app_routes.js", exclude: [/^admin_/, /^api_/]
    )
    JsRoutes.generate!(
    "#{path}/adm_routes.js", include: /^admin_/
    )
    JsRoutes.generate!(
      "#{path}/api_routes.js", include: /^api_/, default_url_options: {format: "json"}
    )
  end
end
```

<div id="definitions"></div>

#### Typescript Definitions

JsRoutes has typescript support out of the box.

Restrictions:

* Only available if `module_type` is set to `ESM` (strongly recommended and default).
* Webpacker Automatic Updates are not available because typescript compiler can not be configured to understand `.erb` extensions.

For the basic setup of typscript definitions  see [Quick Start](#quick-start) setup.
More advanced setup would involve calling manually:

``` ruby
JsRoutes.definitions! # to output to file
# or
JsRoutes.definitions # to output to string
```

Even more advanced setups can be achieved by setting `module_type` to `DTS` inside [configuration](#module_type)
which will cause any `JsRoutes` instance to generate defintions instead of routes themselves.

<div id="sprockets"></div>

### Sprockets (Deprecated)

If you are using [Sprockets](https://github.com/rails/sprockets-rails) you may configure js-routes in the following way.

Setup the initializer (e.g. `config/initializers/js_routes.rb`):

``` ruby
JsRoutes.setup do |config|
  config.module_type = nil
  config.namespace = 'Routes'
end
```

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

## Configuration

You can configure JsRoutes in two main ways. Either with an initializer (e.g. `config/initializers/js_routes.rb`):

``` ruby
JsRoutes.setup do |config|
  config.option = value
end
```

Or dynamically in JavaScript, although only [Formatter Options](#formatter-options) are supported:

``` js
import {configure, config} from 'routes'

configure({
  option: value
});
config(); // current config
```

### Available Options

#### Generator Options

Options to configure JavaScript file generator. These options are only available in Ruby context but not JavaScript.

<div id='module-type'></div>

* `module_type` - JavaScript module type for generated code. [Article](https://dev.to/iggredible/what-the-heck-are-cjs-amd-umd-and-esm-ikm)
  * Options: `ESM`, `UMD`, `CJS`, `AMD`, `DTS`, `nil`.
  * Default: `ESM`
  * `nil` option can be used in case you don't want generated code to export anything.
* `documentation` - specifies if each route should be annotated with [JSDoc](https://jsdoc.app/) comment
  * Default: `true`
* `exclude` - Array of regexps to exclude from routes.
  * Default: `[]`
  * The regexp applies only to the name before the `_path` suffix, eg: you want to match exactly `settings_path`, the regexp should be `/^settings$/`
* `include` - Array of regexps to include in routes.
  * Default: `[]`
  * The regexp applies only to the name before the `_path` suffix, eg: you want to match exactly `settings_path`, the regexp should be `/^settings$/`
* `namespace` - global object used to access routes.
  * Only available if `module_type` option is set to `nil`.
  * Supports nested namespace like `MyProject.routes`
  * Default: `nil`
* `camel_case` - specifies if route helpers should be generated in camel case instead of underscore case.
  * Default: `false`
* `url_links` - specifies if `*_url` helpers should be generated (in addition to the default `*_path` helpers).
  * Default: `false`
  * Note: generated URLs will first use the protocol, host, and port options specified in the route definition. Otherwise, the URL will be based on the option specified in the `default_url_options` config. If no default option has been set, then the URL will fallback to the current URL based on `window.location`.
* `compact` - Remove `_path` suffix in path routes(`*_url` routes stay untouched if they were enabled)
  * Default: `false`
  * Sample route call when option is set to true: `users() // => /users`
* `application` - a key to specify which rails engine you want to generate routes too.
  * This option allows to only generate routes for a specific rails engine, that is mounted into routes instead of all Rails app routes
  * It is recommended to wrap the value with `lambda`. This will reduce the reliance on order during initialization your application.
  * Default: `-> { Rails.application }`
* `file` - a file location where generated routes are stored
  * Default: `app/javascript/routes.js` if setup with Webpacker, otherwise `app/assets/javascripts/routes.js` if setup with Sprockets.
* `optional_definition_params` - make all route paramters in definition optional
  * See [related compatibility issue](#optional-definition-params)
  * Default: `false`
* `banner` - specify a JSDoc comment on top of the file.
  * It is not stripped by minifiers by default and helps to originate the content when debugging the build.
  * You may want to control how much information from backend is exposed to potential attacker at the cost of your own comfort.
  * See [JSDoc Guide](https://github.com/shri/JSDoc-Style-Guide/blob/master/README.md#files)
  * Supports a lazy generation with `Proc`.
  * Default: A string that generates the following:

```
/**
 * File generated by js-routes 2.3.1 on 2024-12-04 09:45:59 +0100
 * Based on Rails 7.2.0 routes of App
 */
```

<div id="formatter-options"></div>

#### Formatter Options

Options to configure routes formatting. These options are available both in Ruby and JavaScript context.

* `default_url_options` - default parameters used when generating URLs
  * Example: `{format: "json", trailing_slash: true, protocol: "https", subdomain: "api", host: "example.com", port: 3000}`
  * See [`url_for` doc](https://api.rubyonrails.org/classes/ActionDispatch/Routing/UrlFor.html#method-i-url_for) for list of supported options
  * Default: `{}`
* `serializer` - a JS function that serializes a Javascript Hash object into URL paramters like `{a: 1, b: 2} => "a=1&b=2"`.
  * Default: `nil`. Uses built-in serializer compatible with Rails
  * Example: `jQuery.param` - use jQuery's serializer algorithm. You can attach serialize function from your favorite AJAX framework.
  * Example: `function (object) { ... }` - use completely custom serializer of your application.
* `special_options_key` - a special key that helps JsRoutes to destinguish serialized model from options hash
  * This option exists because JS doesn't provide a difference between an object and a hash
  * Default: `_options`


## Usage

Configuration above will create a nice javascript file with `Routes` object that has all the rails routes available:

``` js
import {
  user_path, user_project_path, company_path
} from 'routes';

users_path()
  // => "/users"

user_path(1)
  // => "/users/1"

user_path(1, {format: 'json'})
  // => "/users/1.json"

user_path(1, {anchor: 'profile'})
  // => "/users/1#profile"

new_user_project_path(1, {format: 'json'})
  // => "/users/1/projects/new.json"

user_project_path(1,2, {q: 'hello', custom: true})
  // => "/users/1/projects/2?q=hello&custom=true"

user_project_path(1,2, {hello: ['world', 'mars']})
  // => "/users/1/projects/2?hello%5B%5D=world&hello%5B%5D=mars"

var google = {id: 1, name: "Google"};
company_path(google)
  // => "/companies/1"

var google = {id: 1, name: "Google", to_param: "google"};
company_path(google)
  // => "/companies/google"
```

In order to make routes helpers available globally:

``` js
import * as Routes from '../routes';
jQuery.extend(window, Routes)
```

### Get spec of routes and required params

Possible to get `spec` of route by function `toString`:

```js
import {user_path, users_path}  from '../routes'

users_path.toString() // => "/users(.:format)"
user_path.toString() // => "/users/:id(.:format)"
```


Route function also contain method `requiredParams` inside which returns required param names array:

```js
users_path.requiredParams() // => []
user_path.requiredParams() // => ['id']
```


## Rails Compatibility

JsRoutes tries to replicate the Rails routing API as closely as possible. 
There are only 2 known issues with compatibility that happen very rarely and have their workarounds.

If you find any incompatibilities outside of ones below, please [open an issue](https://github.com/railsware/js-routes/issues/new).

### Object and Hash distinction issue

Sometimes the destinction between JS Hash and Object can not be found by JsRoutes.
In this case you would need to pass a special key to help:

``` js
import {company_project_path} from '../routes'

company_project_path({company_id: 1, id: 2})
    // => Not enough parameters
company_project_path({company_id: 1, id: 2, _options: true})
    // => "/companies/1/projects/2"
```

Use `special_options_key` to configure the `_options` parameter name.

<div id="optional-definition-params"></div>

### Rails required parameters specified as optional

Rails is very flexible on how route parameters can be specified.
All of the following calls will make the same result:

``` ruby
# Given route
# /inboxes/:inbox_id/messages/:message_id/attachments/:id
# every call below returns:
# => "/inboxes/1/messages/2/attachments/3"

inbox_message_attachment_path(1, 2, 3)
inbox_message_attachment_path(1, 2, id: 3)
inbox_message_attachment_path(1, message_id: 2, id: 3)
inbox_message_attachment_path(inbox_id: 1, message_id: 2, id: 3)

# including these mad versions
inbox_message_attachment_path(2, inbox_id: 1, id: 3)
inbox_message_attachment_path(1, 3, message_id: 2)
inbox_message_attachment_path(3, inbox_id: 1, message_id: 2)
```

While all of these methods are supported by JsRoutes, it is impossible to support them in `DTS` type definitions.
If you are using routes like this, use the following configuration that will prevent required parameters presence to be validated by definition:

``` ruby
JsRoutes.setup do |c|
  c.optional_definition_params = true
end
```

This will enforce the following route signature:

``` typescript
export const inbox_message_attachment_path: ((
  inbox_id?: RequiredRouteParameter,
  message_id?: RequiredRouteParameter,
  id?: RequiredRouteParameter,
  options?: RouteOptions
) => string) & RouteHelperExtras;
```

That will make every call above valid.

## What about security?

JsRoutes itself does not have security holes.
It makes URLs without access protection more reachable by potential attacker.
If that is an issue for you, you may use one of the following solutions:

### ESM Tree shaking

Make sure `module_type` is set to `ESM` (the default). Modern JS bundlers like
[Webpack](https://webpack.js.org) can statically determine which ESM exports are used, and remove
the unused exports to reduce bundle size. This is known as [Tree
Shaking](https://webpack.js.org/guides/tree-shaking/).

JS files can use named imports to import only required routes into the file, like:

``` javascript
import {
  inbox_path,
  inboxes_path,
  inbox_message_path,
  inbox_attachment_path,
  user_path,
} from '../routes'
```

JS files can also use star imports (`import * as`) for tree shaking, as long as only explicit property accesses are used.

``` javascript
import * as routes from '../routes';

console.log(routes.inbox_path); // OK, only `inbox_path` is included in the bundle

console.log(Object.keys(routes)); // forces bundler to include all exports, breaking tree shaking
```

### Exclude/Include options

Split your routes into multiple files related to each section of your website like:

``` ruby
JsRoutes.generate!('app/javascript/admin-routes.js', include: /^admin_/) %>
JsRoutes.generate!('app/javascript/app-routes.js', exclude: /^admin_/) %>
```

## Advantages over alternatives

There are some alternatives available. Most of them has only basic feature and don't reach the level of quality I accept.
Advantages of this one are:

* Actively maintained
* [ESM Tree shaking](https://webpack.js.org/guides/tree-shaking/) support
* Rich options set
* Full rails compatibility
* Support Rails `#to_param` convention for seo optimized paths
* Well tested
