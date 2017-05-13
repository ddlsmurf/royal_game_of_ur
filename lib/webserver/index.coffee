
Express = require 'express'
BodyParser = require 'body-parser'
Engines = require 'consolidate'
Compression = require 'compression'
CookieParser = require 'cookie-parser'
ErrorHandler = require 'errorhandler'
SocketIO = require 'socket.io'

Utils = require '../utils'

module.exports = (App, config, callback) ->
  debugMode = config.overrideDebugMode ? (process.env.NODE_ENV isnt "production")

  App.webserver = webserver = Express()
  webserver.Express = Express

  webserver.set 'views', config.server.views.path
  webserver.engine config.server.views.extension, Engines[config.server.views.compileWith]
  webserver.set 'view engine', config.server.views.extension
  webserver.set 'port', process.env.PORT || config.server.port || 3000
  webserver.disable 'x-powered-by'

  webserver.use Compression()
  webserver.use BodyParser.json()
  webserver.use BodyParser.urlencoded {extended: true}
  webserver.use CookieParser()
  webserver.use Express.static config.watch.compiledDir
  
  webserver.use ErrorHandler() if debugMode

  webserver.registerViewLocals = do ->
    helpers = {}
    checkIsEmpty = (obj) -> throw Error("Unkown keys in response.locals: #{keys?.join(",")}") if (keys = Object.keys(obj)).length
    webserver.use (req, res, next) ->
      checkIsEmpty res.locals
      # Utils.merge res.locals, helpers
      res.locals = helpers
      next()
    (data...) -> Utils.merge helpers, data...

  webserver.use require("./middleware/request_logger") { req: debugMode, reqBody: debugMode, res: true }

  webserver.registerViewLocals
    config:    config.viewLocalConfig
    prod:      !debugMode
    reload:    config.liveReload.enabled
    optimize:  config.isOptimize ? false
    cachebust: if debugMode then "?b=#{(new Date()).getTime()}" else ''

  [
    ['/', './routes']
  ].forEach ([point, mw]) -> webserver.use point, require(mw)(App, config, Express)

  bind_interface = process.env.BINDIF ? '127.0.0.1'
  listener = webserver.listen webserver.get('port'), bind_interface,  ->
    console.log "http://#{bind_interface}:#{webserver.get('port')}"
    webserver.io = SocketIO.listen listener
    callback listener, webserver.io
