ParameterMissing = (@message) -> #
ParameterMissing:: = new Error()
defaults =
  prefix: "PREFIX"
  default_url_options: DEFAULT_URL_OPTIONS

NodeTypes = NODE_TYPES
Utils =

  serialize: (obj) ->
    return ""  unless obj
    if window.jQuery
      result = window.jQuery.param(obj)
      return (if not result then "" else result)
    s = []
    for own key, prop of obj when prop?
      if @getObjectType(prop) is "array"
        for val, i in prop
          s.push "#{key}#{encodeURIComponent("[]")}=#{encodeURIComponent(val.toString())}"
      else
        s.push "#{key}=#{encodeURIComponent(prop.toString())}"
    return "" unless s.length
    s.join("&")

  clean_path: (path) ->
    path = path.split("://")
    last_index = path.length - 1
    path[last_index] = path[last_index].replace(/\/+/g, "/").replace(/\/$/m, "")
    path.join "://"

  set_default_url_options: (optional_parts, options) ->
    for part, i in optional_parts
      if not options.hasOwnProperty(part) and defaults.default_url_options.hasOwnProperty(part)
        options[part] = defaults.default_url_options[part]

  extract_anchor: (options) ->
    anchor = ""
    if options.hasOwnProperty("anchor")
      anchor = "##{options.anchor}"
      delete options.anchor
    anchor

  extract_options: (number_of_params, args) ->
    ret_value = {}
    if args.length > number_of_params and @getObjectType(args[args.length - 1]) is "object"
      ret_value = args.pop()
    ret_value

  path_identifier: (object) ->
    return "0"  if object is 0
    # null, undefined, false or ''
    return ""  unless object
    property = object
    if @getObjectType(object) is "object"
      property = object.to_param or object.id or object
      property = property.call(object) if @getObjectType(property) is "function"
    property.toString()

  clone: (obj) ->
    return obj if !obj? or "object" isnt @getObjectType(obj)
    copy = obj.constructor()
    copy[key] = attr for own key, attr of obj
    copy

  prepare_parameters: (required_parameters, actual_parameters, options) ->
    result = @clone(options) or {}
    result[val] = actual_parameters[i] for val, i in required_parameters
    result

  build_path: (required_parameters, optional_parts, route, args) ->
    args = Array::slice.call(args)
    opts = @extract_options(required_parameters.length, args)
    throw new Error("Too many parameters provided for path") if args.length > required_parameters.length
    parameters = @prepare_parameters(required_parameters, args, opts)
    @set_default_url_options optional_parts, parameters
    result = "#{@get_prefix()}#{@visit(route, parameters)}"
    url = Utils.clean_path("#{result}#{@extract_anchor(parameters)}")
    url += "?#{url_params}" if (url_params = @serialize(parameters)).length
    url
  #
  # This function is JavaScript impelementation of the
  # Journey::Visitors::Formatter that builds route by given parameters
  # from route binary tree.
  # Binary tree is serialized in the following way:
  # [node type, left node, right node ]
  #
  # @param  {Boolean} optional  Marks the currently visited branch as optional.
  # If set to `true`, this method will not throw when encountering
  # a missing parameter (used in recursive calls).
  #
  visit: (route, parameters, optional = false) ->
    [type, left, right] = route
    switch type
      when NodeTypes.GROUP
        @visit left, parameters, true
      when NodeTypes.STAR
        @visit_globbing left, parameters, true
      when NodeTypes.LITERAL, NodeTypes.SLASH, NodeTypes.DOT
        left
      when NodeTypes.CAT
        left_part = @visit(left, parameters, optional)
        right_part = @visit(right, parameters, optional)
        return "" if optional and not (left_part and right_part)
        "#{left_part}#{right_part}"
      when NodeTypes.SYMBOL
        value = parameters[left]
        if value?
          delete parameters[left]
          return @path_identifier(value)
        if optional
          "" # missing parameter
        else
          throw new ParameterMissing("Route parameter missing: #{left}")
      #
      # I don't know what is this node type
      # Please send your PR if you do
      #
      # when NodeTypes.OR:
      else
        throw new Error("Unknown Rails node type")

  #
  # This method convert value for globbing in right value for rails route
  #
  visit_globbing: (route, parameters, optional) ->
    [type, left, right] = route
    value = parameters[left]
    return @visit(route, parameters, optional) unless value?
    parameters[left] = switch @getObjectType(value)
      when "array"
        value.join("/")
      when "object"
        v = if value[left] then value[left] else value
        if @getObjectType(v) is "string"
          v
        else
          @serialize(v)
      else
        value
    @visit route, parameters, optional

  #
  # This method check and return prefix from options
  #
  get_prefix: ->
    prefix = defaults.prefix
    prefix = (if prefix.match("/$") then prefix else "#{prefix}/") if prefix isnt ""
    prefix

  #
  # This is helper method to define object type.
  # The typeof operator is probably the biggest design flaw of JavaScript, simply because it's basically completely broken.
  #
  # Value               Class      Type
  # -------------------------------------
  # "foo"               String     string
  # new String("foo")   String     object
  # 1.2                 Number     number
  # new Number(1.2)     Number     object
  # true                Boolean    boolean
  # new Boolean(true)   Boolean    object
  # new Date()          Date       object
  # new Error()         Error      object
  # [1,2,3]             Array      object
  # new Array(1, 2, 3)  Array      object
  # new Function("")    Function   function
  # /abc/g              RegExp     object
  # new RegExp("meow")  RegExp     object
  # {}                  Object     object
  # new Object()        Object     object
  #
  # What is why I use Object.prototype.toString() to know better type of variable. Or use jQuery.type, if it available.
  # _classToTypeCache used for perfomance cache of types map (underscore at the beginning mean private method - of course it doesn't realy private).
  #
  _classToTypeCache: null
  _classToType: ->
    return @_classToTypeCache if @_classToTypeCache?
    @_classToTypeCache = {}
    for name in "Boolean Number String Function Array Date RegExp Undefined Null".split(" ")
      @_classToTypeCache["[object " + name + "]"] = name.toLowerCase()
    @_classToTypeCache
  getObjectType: (obj) ->
    return window.jQuery.type(obj) if window.jQuery and window.jQuery.type?
    strType = Object::toString.call(obj)
    @_classToType()[strType] or "object"

  namespace: (root, namespaceString) ->
    parts = (if namespaceString then namespaceString.split(".") else [])
    return unless parts.length
    current = parts.shift()
    root[current] = root[current] or {}
    Utils.namespace root[current], parts.join(".")

Utils.namespace window, "NAMESPACE"
window.NAMESPACE = ROUTES
window.NAMESPACE.options = defaults
