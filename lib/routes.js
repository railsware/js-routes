(function() {
  var NodeTypes, ParameterMissing, Utils, defaults,
    __hasProp = {}.hasOwnProperty;

  ParameterMissing = function(message) {
    this.message = message;
  };

  ParameterMissing.prototype = new Error();

  defaults = {
    prefix: "PREFIX",
    default_url_options: DEFAULT_URL_OPTIONS
  };

  NodeTypes = NODE_TYPES;

  Utils = {
    serialize: function(obj) {
      var i, key, prop, result, s, val, _i, _len;
      if (!obj) {
        return "";
      }
      if (window.jQuery) {
        result = window.jQuery.param(obj);
        return (!result ? "" : "?" + result);
      }
      s = [];
      for (key in obj) {
        if (!__hasProp.call(obj, key)) continue;
        prop = obj[key];
        if (prop != null) {
          if (prop instanceof Array) {
            for (i = _i = 0, _len = prop.length; _i < _len; i = ++_i) {
              val = prop[i];
              s.push("" + key + (encodeURIComponent("[]")) + "=" + (encodeURIComponent(val.toString())));
            }
          } else {
            s.push("" + key + "=" + (encodeURIComponent(prop.toString())));
          }
        }
      }
      if (!s.length) {
        return "";
      }
      return "?" + (s.join("&"));
    },
    clean_path: function(path) {
      var last_index;
      path = path.split("://");
      last_index = path.length - 1;
      path[last_index] = path[last_index].replace(/\/+/g, "/").replace(/\/$/m, "");
      return path.join("://");
    },
    set_default_url_options: function(optional_parts, options) {
      var i, part, _i, _len, _results;
      _results = [];
      for (i = _i = 0, _len = optional_parts.length; _i < _len; i = ++_i) {
        part = optional_parts[i];
        if (!options.hasOwnProperty(part) && defaults.default_url_options.hasOwnProperty(part)) {
          _results.push(options[part] = defaults.default_url_options[part]);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    },
    extract_anchor: function(options) {
      var anchor;
      anchor = "";
      if (options.hasOwnProperty("anchor")) {
        anchor = "#" + options.anchor;
        options.anchor = null;
      }
      return anchor;
    },
    extract_options: function(number_of_params, args) {
      var ret_value;
      ret_value = {};
      if (args.length > number_of_params && typeof args[args.length - 1] === "object") {
        ret_value = args.pop();
      }
      return ret_value;
    },
    path_identifier: function(object) {
      var property;
      if (object === 0) {
        return "0";
      }
      if (!object) {
        return "";
      }
      property = object;
      if (typeof object === "object") {
        property = object.to_param || object.id || object;
        if (typeof property === "function") {
          property = property.call(object);
        }
      }
      return property.toString();
    },
    clone: function(obj) {
      var attr, copy, key;
      if (null === obj || "object" !== typeof obj) {
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
    prepare_parameters: function(required_parameters, actual_parameters, options) {
      var i, result, val, _i, _len;
      result = this.clone(options) || {};
      for (i = _i = 0, _len = required_parameters.length; _i < _len; i = ++_i) {
        val = required_parameters[i];
        result[val] = actual_parameters[i];
      }
      return result;
    },
    build_path: function(required_parameters, optional_parts, route, args) {
      var opts, parameters, result;
      args = Array.prototype.slice.call(args);
      opts = this.extract_options(required_parameters.length, args);
      if (args.length > required_parameters.length) {
        throw new Error("Too many parameters provided for path");
      }
      parameters = this.prepare_parameters(required_parameters, args, opts);
      this.set_default_url_options(optional_parts, parameters);
      result = "" + (Utils.get_prefix()) + (this.visit(route, parameters));
      return Utils.clean_path("" + result + (Utils.extract_anchor(parameters))) + Utils.serialize(parameters);
    },
    visit: function(route, parameters, optional) {
      var left, left_part, right, right_part, type, value;
      type = route[0], left = route[1], right = route[2];
      switch (type) {
        case NodeTypes.GROUP:
        case NodeTypes.STAR:
          return this.visit(left, parameters, true);
        case NodeTypes.LITERAL:
        case NodeTypes.SLASH:
        case NodeTypes.DOT:
          return left;
        case NodeTypes.CAT:
          left_part = this.visit(left, parameters, optional);
          right_part = this.visit(right, parameters, optional);
          if (optional && !(left_part && right_part)) {
            return "";
          }
          return "" + left_part + right_part;
        case NodeTypes.SYMBOL:
          value = parameters[left];
          if (value != null) {
            parameters[left] = null;
            return this.path_identifier(value);
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
    get_prefix: function() {
      var prefix;
      prefix = defaults.prefix;
      if (prefix !== "") {
        prefix = (prefix.match("/$") ? prefix : "" + prefix + "/");
      }
      return prefix;
    },
    namespace: function(root, namespaceString) {
      var current, parts;
      parts = (namespaceString ? namespaceString.split(".") : []);
      if (!parts.length) {
        return;
      }
      current = parts.shift();
      root[current] = root[current] || {};
      return Utils.namespace(root[current], parts.join("."));
    }
  };

  Utils.namespace(window, "NAMESPACE");

  window.NAMESPACE = ROUTES;

  window.NAMESPACE.options = defaults;

}).call(this);
