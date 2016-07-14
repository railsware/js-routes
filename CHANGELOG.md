## master

## v1.2.7

* Drop support 1.9.3
* Add helper for indexOf, if no native implementation in JS engine
* Add sprockets3 compatibility
* Bugfix domain defaults to path #197

## v1.2.6

* Use default prefix from `Rails.application.config.relative_url_root` #186
* Bugfix route globbing with optional fragments bug #191

## v1.2.5

* Bugfix subdomain default parameter in routes #184
* Bugfix infinite recursion in some specific route sets #183

## v1.2.4

* Additional bugfixes to support all versions of Sprockets: 2.x and 3.x

## v1.2.3

* Sprockets ~= 3.0 support

## v1.2.2

* Sprockets ~= 3.0 support
* Support default parameters specified in route.rb file

## v1.2.1

* Fixes for Rails 5

## v1.2.0

* Support host, port and protocol inline parameters
* Support host, port and protocol parameters given to a route explicitly
* Remove all incompatibilities between actiondispatch and js-routes in handling route URLs

## v1.1.2

* Bugfix support nested object null parameters #164
* Bugfix support for nested optional parameters #162 #163

## v1.1.1

* Bugfix regression in serialisation on blank strings caused by [#155](https://github.com/railsware/js-routes/pull/155/files)

## v1.1.0

* Ensure routes are loaded, prior to generating them [#148](https://github.com/railsware/js-routes/pull/148)
* Use `flat_map` rather than `map{...}.flatten` [#149](https://github.com/railsware/js-routes/pull/149)
* URL escape routes.rb url to fix bad URI(is not URI?) error [#150](https://github.com/railsware/js-routes/pull/150)
* Fix for rails 5 - test rails-edge on travis allowing failure [#151](https://github.com/railsware/js-routes/pull/151)
* Adds `serializer` option [#155](https://github.com/railsware/js-routes/pull/155/files)

## v1.0.1

* Support sprockets-3
* Performance optimization of include/exclude options

## v1.0.0

 * Add the compact mode [#125](https://github.com/railsware/js-routes/pull/125)
 * Add support for host, protocol, and port configuration [#137](https://github.com/railsware/js-routes/pull/137)
 * Routes path specs [#135](https://github.com/railsware/js-routes/pull/135)
 * Support Rails 4.2 and Ruby 2.2 [#140](https://github.com/railsware/js-routes/pull/140)

## v0.9.9

* Bugfix Rails Engine subapplication route generation when they are nested [#120](https://github.com/railsware/js-routes/pull/120)

## v0.9.8

* Support AMD/Require.js [#111](https://github.com/railsware/js-routes/pull/111)
* Support trailing slash [#106](https://github.com/railsware/js-routes/pull/106)

## v0.9.7

* Depend on railties [#97](https://github.com/railsware/js-routes/pull/97)
* Fix typeof error for IE [#95](https://github.com/railsware/js-routes/pull/95)
* Fix testing on ruby-head [#92](https://github.com/railsware/js-routes/pull/92)
* Correct thread safety issue in js-routes generation [#90](https://github.com/railsware/js-routes/pull/90)
* Use the `of` operator to detect for `to_param` and `id` in objects [#87](https://github.com/railsware/js-routes/pull/87)
