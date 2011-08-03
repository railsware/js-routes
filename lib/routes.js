var Routes = {

  IDENTITY

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
  
  less_check_path: function(path) {
    return path.replace(/\.$/m, '');
  },
  
  extract_options: function(args) {
    if (typeof(args[args.length - 1]) == "object") {
      return Array.prototype.slice.call(args).pop();
    } else {
      return {};
    }
  
  }

}
