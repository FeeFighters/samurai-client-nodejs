(function() {
  var colors, errors, extend, flattenObject, https, querystring, url, xml, _ref;

  url = require('url');

  https = require('https');

  querystring = require('querystring');

  _ref = require('./helpers'), extend = _ref.extend, flattenObject = _ref.flattenObject;

  errors = require('./errors');

  xml = require('./xml_parser');

  colors = require('colors');

  module.exports = (function() {
    var authHeader, config, defaultData, errorFromStatus, get, handleResponse, post, put, request, setup;
    authHeader = '';
    defaultData = {};
    config = {
      site: 'https://api.samurai.feefighters.com/v1/',
      debug: false
    };
    setup = function(c) {
      var parsedUrl, _ref2, _ref3, _ref4;
      if (c == null) c = {};
      extend(config, c);
      parsedUrl = url.parse(config.site);
      if ((_ref2 = config.host) == null) config.host = parsedUrl.host;
      if ((_ref3 = config.port) == null) {
        config.port = parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 80);
      }
      if ((_ref4 = config.path) == null) config.path = parsedUrl.pathname;
      return authHeader = (new Buffer(config.merchant_key + ':' + config.merchant_password)).toString('base64');
    };
    errorFromStatus = function(status) {
      switch (status.toString()) {
        case '200':
          return null;
        case '400':
          return errors.BadRequestError();
        case '401':
          return errors.AuthenticationRequiredError();
        case '403':
          return errors.AuthorizationError();
        case '404':
          return errors.NotFoundError();
        case '406':
          return errors.NotAcceptableError();
        case '500':
          return errors.InternalServerError();
        case '503':
          return errors.DownForMaintenanceError();
        default:
          return errors.UnexpectedError('Unexpected HTTP response: ' + status);
      }
    };
    handleResponse = function(callback, r) {
      return function(res) {
        var body;
        body = '';
        res.setEncoding('utf8');
        res.on('data', function(chunk) {
          return body += chunk;
        });
        return res.on('end', function() {
          var contentType, err, k, response, v, _ref2;
          if (config.debug) {
            console.log('\n\n-- REQUEST options:');
            console.log(r.options);
            console.log('-- REQUEST data:');
            console.log(r.data);
            console.log('-- RESPONSE headers: ');
            console.log(res.headers);
            console.log('-- RESPONSE body: ');
            console.log(body);
          }
          err = errorFromStatus(res.statusCode);
          if (err && config.debug) {
            console.log('-- [err] '.red + 'status:', res.statusCode);
          }
          _ref2 = res.headers;
          for (k in _ref2) {
            v = _ref2[k];
            if (k.toLowerCase() === 'content-type') contentType = v;
          }
          try {
            if (contentType.match(/(text|application)\/xml/)) {
              response = xml.parse(body);
            }
            if (contentType.match(/(text|application)\/json/)) {
              response = JSON.parse(body);
            }
          } catch (error) {
            response = null;
          }
          return typeof callback === "function" ? callback(err, response) : void 0;
        });
      };
    };
    request = function(method, path, data, callback) {
      var options, req;
      options = {
        host: config.host,
        port: config.port,
        path: config.path + path,
        method: method,
        headers: {
          'Authorization': authHeader,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      };
      data = JSON.stringify(extend(extend({}, defaultData), data));
      options.headers['Content-Length'] = data.length;
      req = https.request(options, handleResponse(callback, {
        options: options,
        data: data
      }));
      if (data != null) req.write(data);
      return req.end();
    };
    get = function(path, data, callback) {
      return request('GET', path, data, callback);
    };
    post = function(path, data, callback) {
      return request('POST', path, data, callback);
    };
    put = function(path, data, callback) {
      return request('PUT', path, data, callback);
    };
    return {
      get: get,
      post: post,
      put: put,
      setup: setup,
      config: config
    };
  })();

}).call(this);
