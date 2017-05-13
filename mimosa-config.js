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
            "": []
            }
        }
    },
    "viewLocalConfig": {
    }
}