((root, factory) ->
  # globalJsObject
  createGlobalJsRoutesObject = ->
    # namespace function, private
    namespace = (mainRoot, namespaceString) ->
      parts = (if namespaceString then namespaceString.split(".") else [])
      return unless parts.length
      current = parts.shift()
      mainRoot[current] = mainRoot[current] or {}
      namespace mainRoot[current], parts.join(".")
    # object
    namespace(root, "NAMESPACE")
    root.NAMESPACE = factory(root)
    root.NAMESPACE
  # Set up Routes appropriately for the environment.
  if typeof define is "function" and define.amd
    # AMD
    define [], -> createGlobalJsRoutesObject()
  else
    # Browser globals
    createGlobalJsRoutesObject()
)(this, (root) ->
  # begin function
  ParameterMissing = (@message) -> #
  ParameterMissing:: = new Error()
  defaults =
    prefix: "PREFIX"
    defaultUrlOptions: DEFAULT_URL_OPTIONS

  NodeTypes = NODE_TYPES

  Utils =

    serialize: (object, prefix = null) ->
      return ""  unless object
      if !prefix and !(@getObjectType(object) is "object")
        throw new Error("Url parameters should be a javascript hash")

      if root.jQuery
        result = root.jQuery.param(object)
        return (if not result then "" else result)

      s = []
      switch @getObjectType(object)
        when "array"
          for element, i in object
            s.push @serialize(element, "#{prefix}[]")
        when "object"
          for own key, prop of object when prop?
            key = "#{prefix}[#{key}]" if prefix?
            s.push @serialize(prop, key)
        else
          if object
            s.push "#{encodeURIComponent(prefix.toString())}=#{encodeURIComponent(object.toString())}"

      return "" unless s.length
      s.join("&")

    cleanPath: (path) ->
      path = path.split("://")
      lastIndex = path.length - 1
      path[lastIndex] = path[lastIndex].replace(/\/+/g, "/")
      path.join "://"

    setDefaultUrlOptions: (optionalParts, options) ->
      for part, i in optionalParts when (not options.hasOwnProperty(part) and defaults.defaultUrlOptions.hasOwnProperty(part))
        options[part] = defaults.defaultUrlOptions[part]

    extractAnchor: (options) ->
      anchor = ""
      if options.hasOwnProperty("anchor")
        anchor = "##{options.anchor}"
        delete options.anchor
      anchor

    extractTrailingSlash: (options) ->
      trailingSlash = false
      if defaults.defaultUrlOptions.hasOwnProperty("trailing_slash")
        trailingSlash = defaults.defaultUrlOptions.trailing_slash
      if options.hasOwnProperty("trailing_slash")
        trailingSlash = options.trailing_slash
        delete options.trailing_slash
      trailingSlash

    extractOptions: (numberOfParams, args) ->
      lastEl = args[args.length - 1]
      if args.length > numberOfParams or (lastEl? and "object" is @getObjectType(lastEl) and !@lookLikeSerializedModel(lastEl))
        args.pop()
      else
        {}

    lookLikeSerializedModel: (object) ->
      # consider object a model if it have a path identifier properties like id and to_param
      "id" of object or "to_param" of object


    pathIdentifier: (object) ->
      return "0"  if object is 0
      # null, undefined, false or ''
      return "" unless object
      property = object
      if @getObjectType(object) is "object"
        if "to_param" of object
          property = object.to_param
        else if "id" of object
          property = object.id
        else
          property = object

        property = property.call(object) if @getObjectType(property) is "function"
      property.toString()

    clone: (obj) ->
      return obj if !obj? or "object" isnt @getObjectType(obj)
      copy = obj.constructor()
      copy[key] = attr for own key, attr of obj
      copy

    prepareParameters: (requiredParameters, actualParameters, options) ->
      result = @clone(options) or {}
      for val, i in requiredParameters when i < actualParameters.length
        result[val] = actualParameters[i]
      result

    buildPath: (requiredParameters, optionalParts, route, args) ->
      args = Array::slice.call(args)
      opts = @extractOptions(requiredParameters.length, args)

      if args.length > requiredParameters.length
        throw new Error("Too many parameters provided for path")
      parameters = @prepareParameters(requiredParameters, args, opts)
      @setDefaultUrlOptions optionalParts, parameters
      # options
      anchor = @extractAnchor(parameters)
      trailingSlash = @extractTrailingSlash(parameters)
      # path
      result = "#{@getPrefix()}#{@visit(route, parameters)}"
      url = @cleanPath("#{result}")
      # set trailing_slash
      url = url.replace(/(.*?)[\/]?$/, "$1/") if trailingSlash is true
      # set additional url params
      if (urlParams = @serialize(parameters)).length
        url += "?#{urlParams}"
      # set anchor
      url += anchor
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
          @visitGlobbing left, parameters, true
        when NodeTypes.LITERAL, NodeTypes.SLASH, NodeTypes.DOT
          left
        when NodeTypes.CAT
          leftPart = @visit(left, parameters, optional)
          rightPart = @visit(right, parameters, optional)
          return "" if optional and not (leftPart and rightPart)
          "#{leftPart}#{rightPart}"
        when NodeTypes.SYMBOL
          value = parameters[left]
          if value?
            delete parameters[left]
            return @pathIdentifier(value)
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
    visitGlobbing: (route, parameters, optional) ->
      [type, left, right] = route
      # fix for rails 4 globbing
      route[1] = left = left.replace(/^\*/i, "") if left.replace(/^\*/i, "") isnt left
      value = parameters[left]
      return @visit(route, parameters, optional) unless value?
      parameters[left] = switch @getObjectType(value)
        when "array"
          value.join("/")
        else
          value
      @visit route, parameters, optional

    #
    # This method check and return prefix from options
    #
    getPrefix: ->
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
      for name in "Boolean Number String Function Array Date RegExp Object Error".split(" ")
        @_classToTypeCache["[object #{name}]"] = name.toLowerCase()
      @_classToTypeCache
    getObjectType: (obj) ->
      return root.jQuery.type(obj) if root.jQuery and root.jQuery.type?
      return "#{obj}" unless obj?
      (if typeof obj is "object" or typeof obj is "function" then @_classToType()[Object::toString.call(obj)] or "object" else typeof obj)

  # return objects
  JsRoutes = ROUTES
  JsRoutes.options = defaults
  JsRoutes
)