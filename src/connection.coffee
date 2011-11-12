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

  # Sets up the default connection parameters for all requests to the Samurai API.
  # Parameters are passed in a single object. The available parameters are:
  #
  #   * `merchant_key`: Your merchant key. Required.
  #   * `merchant_password`: Your merchant password. Required.
  #   * `processor_token`: Your default processor token. Optional.
  #   * `site`: Root URL to Samurai's API. Default: https://api.samurai.feefighters.com/v1/
  #   * `sandbox`: Tells samurai to include the sandbox=true parameter with payment method requests, 
  #     so you can execute tests with these payment methods on the sandbox processor. Default: false
  #
  setup = (c = {}) ->
    extend(config, c)

    # Extract host, port and default path from site parameter.
    parsedUrl    = url.parse config.site
    config.host ?= parsedUrl.host
    config.port ?= parsedUrl.port or (if parsedUrl.protocol is 'https:' then 443 else 80)
    config.path ?= parsedUrl.pathname

    authHeader = (new Buffer(config.merchant_key + ':' + config.merchant_password)).toString('base64')

  # Returns an error object, corresponding to the HTTP status code returned by Samurai.
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

  # Creates a response handler, which parses the Samurai response, checks it for errors 
  # and then passes the results to `callback`.
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

  # Performs a GET/POST/PUT request to the Samurai API, parses the returned response
  # and then passes it to `callback`. The `data` object will be automatically flattened
  # (i.e. obj: { key: value } will be turned to obj[key]=value) and converted to 
  # query string form.
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

  # Convenience method for making GET requests.
  get = (path, data, callback) ->
    request('GET', path, data, callback)

  # Convenience method for making POST requests.
  post = (path, data, callback) ->
    request('POST', path, data, callback)

  # Convenience method for making PUT requests.
  put = (path, data, callback) ->
    request('PUT', path, data, callback)

  {get, post, put, setup, config}
