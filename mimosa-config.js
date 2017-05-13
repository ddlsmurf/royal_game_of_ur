exports.config = {
  "modules": [
    "copy",
    "server",
    "jshint",
    "csslint",
    "require",
    "minify-js",
    "minify-css",
    "live-reload",
    "bower",
    "coffeescript",
    "stylus",
    "jade"
  ],
  "liveReload": {
    "enabled": true
  },
  "bower": {
    "bowerDir": { "clean": false },
    "copy": {
        "mainOverrides": {
            "bootstrap": [
                "docs/assets/js/bootstrap.js",
                "docs/assets/js/bootstrap.min.js",
                "docs/assets/css/bootstrap.css",
                "docs/assets/css/bootstrap-responsive.css",
                "docs/assets/img/glyphicons-halflings-white.png",
                "docs/assets/img/glyphicons-halflings.png"
                ],
            "": []
            }
        }
    },
    "viewLocalConfig": {
        "clientSideGlobals": {
        }
    }
}