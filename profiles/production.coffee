exports.config =
  "modules": [
    "copy",
    "server",
    "require",
    "minify-js",
    "minify-css",
    "bower",
    "coffeescript",
    "stylus",
    "jade",
    "web-package"
  ]
  liveReload:
    enabled: false
  debugMode: false
  viewLocalConfig:
    debug: false
    clientSideGlobals:
      templateConfig:
        debug: false