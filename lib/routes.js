(function(){

  function ParameterMissing(message) {
   this.message = message;
  }
  ParameterMissing.prototype = new Error(); 

  var defaults = {
    prefix: 'PREFIX',
    format: 'DEFAULT_FORMAT'
  };
  
  var Utils = {

    serialize: function(obj){
      if (obj === null) {return '';}
      var s = [];
      for (prop in obj){
        if (obj[prop]) {
          if (obj[prop] instanceof Array) {
            for (var i=0; i < obj[prop].length; i++) {
              key = prop + encodeURIComponent("[]");
              s.push(key + "=" + encodeURIComponent(obj[prop][i].toString()));
            }
          } else {
            s.push(prop + "=" + encodeURIComponent(obj[prop].toString()));
          }
        }
      }
      if (s.length === 0) {
        return '';
      }
      return "?" + s.join('&');
    },

    clean_path: function(path) {
      return path.replace(/\/+/g, "/").replace(/[\)\(]/g, "").replace(/\.$/m, '').replace(/\/$/m, '');
    },

    set_default_format: function(options) {
      if (!options.hasOwnProperty("format")) options.format = defaults.format;
    },

    extract_anchor: function(options) {
      var anchor = options.hasOwnProperty("anchor") ? options.anchor : null;
      delete options.anchor;
      return anchor ? "#" + anchor : "";
    },

    extract_options: function(number_of_params, args) {
      if (args.length > number_of_params) {
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
        return ((typeof(object.to_param) == "function" && object.to_param()) || object.to_param || object.id || object).toString();
      } else {
        return object.toString();
      }
    },

    build_path: function(required_parameters, route, args) {
      args = Array.prototype.slice.call(args);
      var opts = this.extract_options(required_parameters.length, args);
      this.set_default_format(opts)
      if (args.length > required_parameters.length) {
        throw new Error("Too many parameters provided for path");
      }

      var result = Utils.get_prefix();
      var anchor = Utils.extract_anchor(opts);

      for (var i=0; i < required_parameters.length; i++) {
        opts[required_parameters[i]] = args[i];
      }
      result += this.visit(route, opts)
      return Utils.clean_path(result + anchor) + Utils.serialize(opts);
    },

    visit: function(route, options) {
      var type = route[0];
      var left = route[1];
      var right = route[2];
      switch (type) {
        case "GROUP":
          try {
            return this.visit(left, options);
          } catch(e) {
            if (e instanceof ParameterMissing) {
              return "";
            } else {
              throw e;
            }
          }
        case "CAT":
          return this.visit(left, options) + this.visit(right, options);
        case "SYMBOL":
          var value = options[left];
          if (value) {
            delete options[left];
            return this.path_identifier(value); 
          } else {
            throw new ParameterMissing("Route parameter missing: " + left);
          }
        //case "OR":
          //break;
        //case "STAR":
          //break;
        case "LITERAL":
          return left;
        case "SLASH":
          return left;
        case "DOT":
          return left;
        default:
          throw new Error("Unknown Rails node type");
      }
      
    },

    get_prefix: function(){
      var prefix = defaults.prefix;

      if( prefix !== "" ){
        prefix = prefix.match('\/$') ? prefix : ( prefix + '/');
      }
      
      return prefix;
    }

  };

  window.NAMESPACE = ROUTES;
  window.NAMESPACE.options = defaults;
})();
