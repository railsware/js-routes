## List of breaking changes

### No global objects by default

The default value of `namespace` option is set to `nil` now which means that JsRoutes will no longer generate global `Routes` object out of the box. This is more optimized setup for WebPacker. You can set `namespace` option to whatecer you prefer.


### ParameterMissing error rework

`ParameterMissing` is renamed to `ParametersMissing` error and now list all missing parameters instead of just first encountered in its message. Missing parameters are now available via `ParametersMissing#keys` property.

``` javascript
try {
  Routes.inbox_path()
} catch(error) {
  if (error.name === 'ParametersMissing') {
    console.warn(`Missing route keys ${error.keys.join(', ')}. Ignoring.`)
  } else {
    throw error;
  }
}
```
