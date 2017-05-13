module.exports = ({req, reqHeaders, reqBody, res, resHeaders, prefix, logger}) ->
  logger ?= (a...) -> console.log a...
  globalID = 0
  prefix ?= (id, ip, method, url, req) ->
    suffix = " ##{id} #{ip} #{method} #{url}:"
    -> (new Date().toISOString()) + suffix
  (req, res, next) ->
    id = ++globalID
    header = prefix(id, req.ip, req.method, req.url ? req.originalUrl)
    req.log = (data...) -> console.log header(), data...
    if req
      includeBody = reqBody && req.headers['content-length']
      req.log("->", (
        if reqHeaders || includeBody
          obj = {}
          obj.headers = req.headers if reqHeaders
          obj.content_type = req.headers['content-type'] if (!reqHeaders) && includeBody
          obj.body = req.body if includeBody
          [obj]
        else
          ["Started"]
      )...)
    if res || resHeaders
      previousEnd = res.end
      res.end = ->
        res.end = previousEnd
        res.end.apply(res, arguments)
        args = ["<- Responded #{res.statusCode} - #{res.statusMessage ? ""}"]
        args.push res._headers if resHeaders
        req.log args...
    next()
