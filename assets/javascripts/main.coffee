require
  # urlArgs: "b=#{(new Date()).getTime()}"
  paths:
    jquery: 'vendor/jquery/jquery'
  shim: {
  }, [
    'jquery'
    'templates'
  ], (
    $
    templates
  ) ->
    $("#content").html(templates['main']())