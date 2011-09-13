(function(){

    var defaults = {
        format: 'DEFAULT_FORMAT'
    };
      
    var Utils = {
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

        extract: function(name, options) {
            var o = undefined;
            if (options.hasOwnProperty(name)) {
                o = options[name];
                delete options[name];
            } else if (defaults.hasOwnProperty(name)) {
                o = defaults[name];
            }
            return o;
        },

        extract_format: function(options) {
            var format =  options.hasOwnProperty("format") ? options.format : defaults.format;
            delete options.format;
            return format ? "." + format : "";
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
                return (object.to_param || object.id || object).toString();
            } else {
                return object.toString();
            }
        },

        build_path: function(number_of_params, parts, optional_params, args) {
            args = Array.prototype.slice.call(args);
            var result = "";
            var opts = Utils.extract_options(number_of_params, args);
            if (args.length > number_of_params) {
                throw new Error("Too many parameters provided for path")
            }
            var params_count = 0, optional_params_count = 0;
            for (var i=0; i < parts.length; i++) {
                var part = parts[i];
                if (Utils.optional_part(part)) {
                    var name = optional_params[optional_params_count];
                    optional_params_count++;
                    // try and find the option in opts
                    var optional = Utils.extract(name, opts);
                    if (Utils.specified(optional)) {
                        result += part;
                        result += Utils.path_identifier(optional);
                    }
                } else {
                    result += part;
                    if (params_count < number_of_params) {
                        params_count++;
                        var value = args.shift();
                        if (Utils.specified(value)) {
                            result += Utils.path_identifier(value);
                        } else {
                            throw new Error("Insufficient parameters to build path")
                        }
                    }
                }
            }
            var format = Utils.extract_format(opts);
            return Utils.clean_path(result + format) + Utils.serialize(opts);
        },

        specified: function(value) {
            return !(value === undefined || value === null);
        },

        optional_part: function(part) {
            return part.match(/\(/);
        }

    };

    window.NAMESPACE = ROUTES;
    window.NAMESPACE.defaults = defaults;
})();
