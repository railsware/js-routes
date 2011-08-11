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
      return path.replace(/\.$/m, '').replace(/\/$/m, '');
    },

    extract_format: function(options) {
      var format =  options.hasOwnProperty("format") ? options.format : Utils.default_format;
      delete options.format;
      return format ? "." + format : "";
    },

    extract_options: function(args) {
      return typeof(args[args.length-1]) == "object" ?  args.pop() : {};
    },

    build_path: function(parts, args) {
      args = Array.prototype.slice.call(args);
      result = "";
      var opts = Utils.extract_options(args);
      for (var i=0; i < parts.length; i++) {
        part = parts[i];
        result += part;
        result += args.shift() || "";
      }
      var format = Utils.extract_format(opts);
      return Utils.clean_path(result + format) + Utils.serialize(opts);
    }
  };

  window.NAMESPACE = ROUTES;

})();
