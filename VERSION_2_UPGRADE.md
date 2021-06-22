## Version 2.0 upgrade notes

### Using ESM module by default

The default setting are now changed:

Setting | Old | New 
--- | --- | ---
module\_type | UMD | ESM 
namespace | Routes | nil
documentation | false | true

This is more optimized setup for WebPacker. 
New version of js-routes generates function comment in the [JSDoc](https://jsdoc.app) format.

You can restore the old configuration like this:

``` ruby
JsRoutes.setup do |config|
  config.module_type = 'UMD'
  config.namespace = 'Routes'
  config.documentation = false
end
```

New version of JsRoutes doesn't try to guess your javascript environment module system because JS has generated a ton of legacy module systems in the past. 
[ESM+Webpacker](/Readme.md#webpacker) upgrade is recommended. 


However, if you don't want to follow that pass, specify `module_type` configuration option instead.
Here are supported values:

* CJS
* UMD
* AMD
* ESM
* nil

[Explaination Article](https://dev.to/iggredible/what-the-heck-are-cjs-amd-umd-and-esm-ikm)


### `required_params` renamed

In case you are using `required_params` property, it is now renamed and converted to a method:

``` javascript
// Old style
Routes.post_path.required_params  // => ['id']
// New style
Routes.post_path.requiredParams() // => ['id']
```

### ParameterMissing error rework

`ParameterMissing` is renamed to `ParametersMissing` error and now list all missing parameters instead of just first encountered in its message. Missing parameters are now available via `ParametersMissing#keys` property.

``` javascript
try {
  return Routes.inbox_path();
} catch(error) {
  if (error.name === 'ParametersMissing') {
    console.warn(`Missing route keys ${error.keys.join(', ')}. Ignoring.`);
    return "#";
  } else {
    throw error;
  }
}
```
