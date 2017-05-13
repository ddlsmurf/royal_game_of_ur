require
  # urlArgs: "b=#{(new Date()).getTime()}"
  paths:
    jquery: 'vendor/jquery/jquery'
    bluebird: 'vendor/bluebird/bluebird'
    lodash: 'vendor/lodash/lodash'
    _: 'vendor/lodash/lodash'
    promise: 'vendor/bluebird/bluebird'
  shim: {
  }, [
    'jquery'
    'templates'
  ], (
    $
    templates
  ) ->
    $("#content").html(templates['main']())