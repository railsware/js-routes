(function(){

  var Utils = {

    default_format: 'DEFAULT_FORMAT',

    serialize: function(obj){
      if (obj == null) {return '';}
      var s = [];
      for (prop in obj){
        s.push(prop + "=" + obj[prop]);
      }
      if (s.length == 0) {
        return '';
      }
      return "?" + s.join('&');
    },


    check_parameter: function(param) {
      if (param === undefined) {
        param = '';
      }
      return param;
    },

    check_path: function(path) {
      return path.replace(/\.$/m, '');
    },

    extract_format: function(options) {
      var format =  options.hasOwnProperty("format") ? options.format : Utils.default_format;
      delete options.format;
      return format || "";
    }
  };

  window.NAMESPACE = {
    ROUTES
  };
})();
