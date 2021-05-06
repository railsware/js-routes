## Version 2.0 upgrade notes

### Using ESM module by default

The default setting are now changed:

Setting | Old | New 
--- | --- | ---
module\_type | nil | ESM 
namespace | Routes | nil

This is more optimized setup for WebPacker. You can retain the old configuration this:

``` ruby
JsRoutes.setup do |config|
  config.module_type = nil
  config.namespace = 'Routes'
end
```

However, [ESM+Webpacker](/Readme.md#webpacker) upgrade is recommended. 


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

### JSDoc comment format

New version of js-routes generates function comment in the [JSDoc](https://jsdoc.app) format.
If you have any problems with that disable the annotation:

``` ruby
JsRoutes.setup do |config|
  config.documentation = false
end
```

