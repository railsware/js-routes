(function(){

  var Utils = {

    default_format: 'DEFAULT_FORMAT',

    serialize: function(obj){
      if (obj === null) {return '';}
      var s = [];
      for (prop in obj){
        s.push(prop + "=" + obj[prop]);
      }
      if (s.length === 0) {
        return '';
      }
      return "?" + s.join('&');
    },

    clean_path: function(path) {
      return path.replace(/\/+/g, "/").replace(/[\)\(]/g, "").replace(/\.$/m, '').replace(/\/$/m, '');
    },

    extract_format: function(options) {
      var format =  options.hasOwnProperty("format") ? options.format : Utils.default_format;
      delete options.format;
      return format ? "." + format : "";
    },

    extract_options: function(number_of_params, args) {
      if (args.length >= number_of_params) {
        return typeof(args[args.length-1]) == "object" ?  args.pop() : {};
      } else {
        return {};
      }
    },

    path_identifier: function(object) {
      if (!object) {
        return "";
      }
      if (typeof(object) == "object") {
        return (object.to_param || object.id).toString();
      } else {
        return object.toString();
      }
    },

    build_path: function(number_of_params, parts, args) {
      args = Array.prototype.slice.call(args);
      result = "";
      var opts = Utils.extract_options(number_of_params, args);
      for (var i=0; i < parts.length; i++) {
          value = args.shift();
          part = parts[i];
          if (part.match(/\(/) && value === undefined) {
              // we have an optional part and value is undefined
              // do nothing
          } else if (!part.match(/\(/) && value === undefined) {
              // we have an non-optional part, but value is undefined
              // still print the part, but not the value
              result += part
          } else if (value !== undefined) {
              // if the value is defined print both the part and value
              result += part
              result += Utils.path_identifier(value);
          }
      }
      var format = Utils.extract_format(opts);
      return Utils.clean_path(result + format) + Utils.serialize(opts);
    }
  };

  window.NAMESPACE = ROUTES;

})();
