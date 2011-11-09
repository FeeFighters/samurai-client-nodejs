url                     = require 'url'
https                   = require 'https'
querystring             = require 'querystring'
{extend, flattenObject} = require './helpers'
errors                  = require './errors'
xml                     = require './xml_parser'
colors                  = require 'colors'

module.exports = do ->
  # defaults
  authHeader = ''
  defaultData = {}
  config =
    site: 'https://api.samurai.feefighters.com/v1/'

  setup = (c = {}) ->
    extend(config, c)

    # Extract host, port and default path from site parameter.
    parsedUrl    = url.parse config.site
    config.host ?= parsedUrl.host
    config.port ?= parsedUrl.port or (if parsedUrl.protocol is 'https:' then 443 else 80)
    config.path ?= parsedUrl.pathname

    authHeader = (new Buffer(config.merchant_key + ':' + config.merchant_password)).toString('base64')
    defaultData.sandbox = true if config.sandbox

  errorFromStatus = (status) ->
    switch status.toString()
      when '200' then null
      when '400' then errors.BadRequestError()
      when '401' then errors.AuthenticationRequiredError()
      when '403' then errors.AuthorizationError()
      when '404' then errors.NotFoundError()
      when '406' then errors.NotAcceptableError()
      when '500' then errors.InternalServerError()
      when '503' then errors.DownForMaintenanceError()
      else errors.UnexpectedError('Unexpected HTTP response: ' + status)

  handleResponse = (callback, r) ->
    (res) ->
      body = ''
      res.setEncoding 'utf8'
      res.on 'data', (chunk) ->
        body += chunk

      res.on 'end', ->
        #console.log '-- raw response headers: ', res.headers
        #console.log '-- raw response body: ', body
        err = errorFromStatus(res.statusCode)
        #if err
          #console.log '-- [err] '.red + 'status:', res.statusCode
          #console.log '-- [err] '.red + 'request options:', r.options
          #console.log '-- [err] '.red + 'request data:', r.data
          #console.log '-- [err] '.red + 'raw response headers:', res.headers
          #console.log '-- [err] '.red + 'raw response body:', body

        contentType = v for k, v of res.headers when k.toLowerCase() is 'content-type'

        try
          if contentType.match /(text|application)\/xml/
            response = xml.parse(body)
          
          if contentType.match /(text|application)\/json/
            response = JSON.parse body
        catch error
          response = null

        callback?(err, response)

  request = (method, path, data, callback) ->
    options =
      host: config.host
      port: config.port
      path: config.path + path
      method: method
      headers:
        'Authorization': authHeader,
        'Accept':        'application/json',
        'Content-Type':  'application/x-www-form-urlencoded',

    data = querystring.stringify flattenObject(extend(extend({}, defaultData), data))
    options.headers['Content-Length'] = data.length
    #console.log ' -- sending request with options', options
    #console.log ' -- should send data', data

    req = https.request(options, handleResponse(callback, { options: options, data: data }))
    req.write(data) if data?
    req.end()

  get = (path, data, callback) ->
    request('GET', path, data, callback)

  post = (path, data, callback) ->
    request('POST', path, data, callback)

  put = (path, data, callback) ->
    request('PUT', path, data, callback)

  {get, post, put, setup, config}
