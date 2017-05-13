require
  # urlArgs: "b=#{(new Date()).getTime()}"
  paths:
    jquery: 'vendor/jquery/jquery'
    bluebird: 'vendor/bluebird/bluebird'
    lodash: 'vendor/lodash/lodash'
    _: 'vendor/lodash/lodash'
    promise: 'vendor/bluebird/bluebird'
    bootstrap: 'vendor/bootstrap/bootstrap.min'
  shim: {
    'bootstrap': deps: ['jquery']
  }, [
    'jquery'
    'templates'
    'bootstrap'
  ], (
    $
    templates
    bootstrap
  ) ->
    $("#content").html(templates['main']())