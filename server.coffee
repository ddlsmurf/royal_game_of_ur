App = {}
exports.startServer = (config, callback) ->
  require('./lib/webserver') App, config, callback
