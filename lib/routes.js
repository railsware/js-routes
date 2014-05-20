(function() {
  var __hasProp = {}.hasOwnProperty;

  (function(root, factory) {
    var createGlobalJsRoutesObject;
    createGlobalJsRoutesObject = function() {
      var namespace;
      namespace = function(mainRoot, namespaceString) {
        var current, parts;
        parts = (namespaceString ? namespaceString.split(".") : []);
        if (!parts.length) {
          return;
        }
        current = parts.shift();
        mainRoot[current] = mainRoot[current] || {};
        return namespace(mainRoot[current], parts.join("."));
      };
      namespace(root, "NAMESPACE");
      root.NAMESPACE = factory(root);
      return root.NAMESPACE;
    };
    if (typeof define === "function" && define.amd) {
      return define([], function() {
        return createGlobalJsRoutesObject();
      });
    } else {
      return createGlobalJsRoutesObject();
    }
  })(this, function(root) {
    var JsRoutes, NodeTypes, ParameterMissing, Utils, defaults;
    ParameterMissing = function(message) {
      this.message = message;
    };
    ParameterMissing.prototype = new Error();
    defaults = {
      prefix: "PREFIX",
      defaultUrlOptions: DEFAULT_URL_OPTIONS
    };
    NodeTypes = NODE_TYPES;
    Utils = {
      serialize: function(object, prefix) {
        var element, i, key, prop, result, s, _i, _len;
        if (prefix == null) {
          prefix = null;
        }
        if (!object) {
          return "";
        }
        if (!prefix && !(this.getObjectType(object) === "object")) {
          throw new Error("Url parameters should be a javascript hash");
        }
        if (root.jQuery) {
          result = root.jQuery.param(object);
          return (!result ? "" : result);
        }
        s = [];
        switch (this.getObjectType(object)) {
          case "array":
            for (i = _i = 0, _len = object.length; _i < _len; i = ++_i) {
              element = object[i];
              s.push(this.serialize(element, "" + prefix + "[]"));
            }
            break;
          case "object":
            for (key in object) {
              if (!__hasProp.call(object, key)) continue;
              prop = object[key];
              if (!(prop != null)) {
                continue;
              }
              if (prefix != null) {
                key = "" + prefix + "[" + key + "]";
              }
              s.push(this.serialize(prop, key));
            }
            break;
          default:
            if (object) {
              s.push("" + (encodeURIComponent(prefix.toString())) + "=" + (encodeURIComponent(object.toString())));
            }
        }
        if (!s.length) {
          return "";
        }
        return s.join("&");
      },
      cleanPath: function(path) {
        var lastIndex;
        path = path.split("://");
        lastIndex = path.length - 1;
        path[lastIndex] = path[lastIndex].replace(/\/+/g, "/");
        return path.join("://");
      },
      setDefaultUrlOptions: function(optionalParts, options) {
        var i, part, _i, _len, _results;
        _results = [];
        for (i = _i = 0, _len = optionalParts.length; _i < _len; i = ++_i) {
          part = optionalParts[i];
          if (!options.hasOwnProperty(part) && defaults.defaultUrlOptions.hasOwnProperty(part)) {
            _results.push(options[part] = defaults.defaultUrlOptions[part]);
          }
        }
        return _results;
      },
      extractAnchor: function(options) {
        var anchor;
        anchor = "";
        if (options.hasOwnProperty("anchor")) {
          anchor = "#" + options.anchor;
          delete options.anchor;
        }
        return anchor;
      },
      extractTrailingSlash: function(options) {
        var trailingSlash;
        trailingSlash = false;
        if (defaults.defaultUrlOptions.hasOwnProperty("trailing_slash")) {
          trailingSlash = defaults.defaultUrlOptions.trailing_slash;
        }
        if (options.hasOwnProperty("trailing_slash")) {
          trailingSlash = options.trailing_slash;
          delete options.trailing_slash;
        }
        return trailingSlash;
      },
      extractOptions: function(numberOfParams, args) {
        var lastEl;
        lastEl = args[args.length - 1];
        if (args.length > numberOfParams || ((lastEl != null) && "object" === this.getObjectType(lastEl) && !this.lookLikeSerializedModel(lastEl))) {
          return args.pop();
        } else {
          return {};
        }
      },
      lookLikeSerializedModel: function(object) {
        return "id" in object || "to_param" in object;
      },
      pathIdentifier: function(object) {
        var property;
        if (object === 0) {
          return "0";
        }
        if (!object) {
          return "";
        }
        property = object;
        if (this.getObjectType(object) === "object") {
          if ("to_param" in object) {
            property = object.to_param;
          } else if ("id" in object) {
            property = object.id;
          } else {
            property = object;
          }
          if (this.getObjectType(property) === "function") {
            property = property.call(object);
          }
        }
        return property.toString();
      },
      clone: function(obj) {
        var attr, copy, key;
        if ((obj == null) || "object" !== this.getObjectType(obj)) {
          return obj;
        }
        copy = obj.constructor();
        for (key in obj) {
          if (!__hasProp.call(obj, key)) continue;
          attr = obj[key];
          copy[key] = attr;
        }
        return copy;
      },
      prepareParameters: function(requiredParameters, actualParameters, options) {
        var i, result, val, _i, _len;
        result = this.clone(options) || {};
        for (i = _i = 0, _len = requiredParameters.length; _i < _len; i = ++_i) {
          val = requiredParameters[i];
          if (i < actualParameters.length) {
            result[val] = actualParameters[i];
          }
        }
        return result;
      },
      buildPath: function(requiredParameters, optionalParts, route, args) {
        var anchor, opts, parameters, result, trailingSlash, url, urlParams;
        args = Array.prototype.slice.call(args);
        opts = this.extractOptions(requiredParameters.length, args);
        if (args.length > requiredParameters.length) {
          throw new Error("Too many parameters provided for path");
        }
        parameters = this.prepareParameters(requiredParameters, args, opts);
        this.setDefaultUrlOptions(optionalParts, parameters);
        anchor = this.extractAnchor(parameters);
        trailingSlash = this.extractTrailingSlash(parameters);
        result = "" + (this.getPrefix()) + (this.visit(route, parameters));
        url = this.cleanPath("" + result);
        if (trailingSlash === true) {
          url = url.replace(/(.*?)[\/]?$/, "$1/");
        }
        if ((urlParams = this.serialize(parameters)).length) {
          url += "?" + urlParams;
        }
        url += anchor;
        return url;
      },
      visit: function(route, parameters, optional) {
        var left, leftPart, right, rightPart, type, value;
        if (optional == null) {
          optional = false;
        }
        type = route[0], left = route[1], right = route[2];
        switch (type) {
          case NodeTypes.GROUP:
            return this.visit(left, parameters, true);
          case NodeTypes.STAR:
            return this.visitGlobbing(left, parameters, true);
          case NodeTypes.LITERAL:
          case NodeTypes.SLASH:
          case NodeTypes.DOT:
            return left;
          case NodeTypes.CAT:
            leftPart = this.visit(left, parameters, optional);
            rightPart = this.visit(right, parameters, optional);
            if (optional && !(leftPart && rightPart)) {
              return "";
            }
            return "" + leftPart + rightPart;
          case NodeTypes.SYMBOL:
            value = parameters[left];
            if (value != null) {
              delete parameters[left];
              return this.pathIdentifier(value);
            }
            if (optional) {
              return "";
            } else {
              throw new ParameterMissing("Route parameter missing: " + left);
            }
            break;
          default:
            throw new Error("Unknown Rails node type");
        }
      },
      visitGlobbing: function(route, parameters, optional) {
        var left, right, type, value;
        type = route[0], left = route[1], right = route[2];
        if (left.replace(/^\*/i, "") !== left) {
          route[1] = left = left.replace(/^\*/i, "");
        }
        value = parameters[left];
        if (value == null) {
          return this.visit(route, parameters, optional);
        }
        parameters[left] = (function() {
          switch (this.getObjectType(value)) {
            case "array":
              return value.join("/");
            default:
              return value;
          }
        }).call(this);
        return this.visit(route, parameters, optional);
      },
      getPrefix: function() {
        var prefix;
        prefix = defaults.prefix;
        if (prefix !== "") {
          prefix = (prefix.match("/$") ? prefix : "" + prefix + "/");
        }
        return prefix;
      },
      _classToTypeCache: null,
      _classToType: function() {
        var name, _i, _len, _ref;
        if (this._classToTypeCache != null) {
          return this._classToTypeCache;
        }
        this._classToTypeCache = {};
        _ref = "Boolean Number String Function Array Date RegExp Object Error".split(" ");
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          name = _ref[_i];
          this._classToTypeCache["[object " + name + "]"] = name.toLowerCase();
        }
        return this._classToTypeCache;
      },
      getObjectType: function(obj) {
        if (root.jQuery && (root.jQuery.type != null)) {
          return root.jQuery.type(obj);
        }
        if (obj == null) {
          return "" + obj;
        }
        if (typeof obj === "object" || typeof obj === "function") {
          return this._classToType()[Object.prototype.toString.call(obj)] || "object";
        } else {
          return typeof obj;
        }
      }
    };
    JsRoutes = ROUTES;
    JsRoutes.options = defaults;
    return JsRoutes;
  });

}).call(this);
