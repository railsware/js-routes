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
      return (if not result then "" else "?#{result}")
    s = []
    for own key, prop of obj
      if prop?
        if prop instanceof Array
          for val, i in prop
            s.push "#{key}#{encodeURIComponent("[]")}=#{encodeURIComponent(val.toString())}"
        else
          s.push "#{key}=#{encodeURIComponent(prop.toString())}"
    return "" unless s.length
    "?#{s.join("&")}"

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
      options.anchor = null
    anchor

  extract_options: (number_of_params, args) ->
    ret_value = {}
    if args.length > number_of_params and typeof (args[args.length - 1]) is "object"
      ret_value = args.pop()
    ret_value

  path_identifier: (object) ->
    return "0"  if object is 0
    # null, undefined, false or ''
    return ""  unless object
    property = object
    if typeof (object) is "object"
      property = object.to_param or object.id or object
      property = property.call(object) if typeof (property) is "function"
    property.toString()

  clone: (obj) ->
    return obj if null is obj or "object" isnt typeof obj
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
    result = "#{Utils.get_prefix()}#{@visit(route, parameters)}"
    Utils.clean_path("#{result}#{Utils.extract_anchor(parameters)}") + Utils.serialize(parameters)
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
  visit: (route, parameters, optional) ->
    [type, left, right] = route
    switch type
      when NodeTypes.GROUP, NodeTypes.STAR
        @visit left, parameters, true
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
          parameters[left] = null
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

  get_prefix: ->
    prefix = defaults.prefix
    prefix = (if prefix.match("/$") then prefix else "#{prefix}/") if prefix isnt ""
    prefix

  namespace: (root, namespaceString) ->
    parts = (if namespaceString then namespaceString.split(".") else [])
    return unless parts.length
    current = parts.shift()
    root[current] = root[current] or {}
    Utils.namespace root[current], parts.join(".")

Utils.namespace window, "NAMESPACE"
window.NAMESPACE = ROUTES
window.NAMESPACE.options = defaults