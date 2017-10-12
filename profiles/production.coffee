FS = require('fs')
Path = require('path')

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
    "client-jade-static",
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
  clientJadeStatic:
    context:
      offline: true
      reload: false
      prod: true
      optimize: true
      cachebust: ""
      favicon64: FS.readFileSync("./favicon.ico").toString("base64")
      config:
        clientSideGlobals: {}
      readResource: do ->
        (file) ->
          path = Path.resolve("./public/", file)
          try
            FS.readFileSync(path, 'utf8')
          catch e
            console.error("File #{path} failed to inline:", e)
            null
