JsRoutes.setup do |c|
  # Setup your JS module system:
  # ESM, CJS, AMD, UMD or nil.
  # c.module_type = "ESM"

  # Legacy setup for no modules system.
  # Sets up a global variable `Routes`
  # that holds route helpers.
  # c.module_type = nil
  # c.namespace = "Routes"

  # Follow javascript naming convention
  # but lose the ability to match helper name
  # on backend and frontend consistently.
  # c.camel_case = true

  # Generate only helpers that match specific pattern.
  # c.exclude = [ /^api_/ ]
  # c.include = [ /^admin_/ ]

  # Generate `*_url` helpers besides `*_path`
  # for apps that work on multiple domains.
  # c.url_links = true

  # Setup default URL options similar to rails equivalent.
  # c.default_url_options = {
  #   host: 'example.com', protocol: 'https', format: 'json'
  # }

  # Output location relative to Rails root. Accepts a directory or a full file path:
  #   directory  → c.file = "app/frontend"          # writes app/frontend/routes.js
  #   full path  → c.file = "app/frontend/routes.js"
  # Default: app/javascript/routes.js
  # c.file = "app/javascript/routes.js"

  # More options:
  # @see https://github.com/railsware/js-routes#available-options
end
