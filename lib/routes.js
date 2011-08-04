(function(){

  var Utils = {

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
    }

  };

  window.NAMESPACE = {
    ROUTES
  };
})();
