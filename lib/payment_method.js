(function() {
  var Message, PaymentMethod, camelize, config, extend, get, isEmptyObject, post, put, _ref, _ref2;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty;
  Message = require('./message');
  _ref = require('./helpers'), extend = _ref.extend, camelize = _ref.camelize, isEmptyObject = _ref.isEmptyObject;
  _ref2 = require('./connection'), get = _ref2.get, post = _ref2.post, put = _ref2.put, config = _ref2.config;
  PaymentMethod = (function() {
    var KNOWN_ATTRIBUTES;
    KNOWN_ATTRIBUTES = ['first_name', 'last_name', 'address_1', 'address_2', 'city', 'state', 'zip', 'card_number', 'cvv', 'expiry_month', 'expiry_year', 'custom', 'sandbox'];
    PaymentMethod.create = function(attributes, callback) {
      var paymentMethod;
      if (attributes == null) {
        attributes = {};
      }
      paymentMethod = new PaymentMethod(attributes);
      paymentMethod.save(callback);
      return paymentMethod;
    };
    PaymentMethod.find = function(token, callback) {
      var paymentMethod;
      paymentMethod = new PaymentMethod({
        payment_method_token: token
      });
      get(paymentMethod.pathFor('show'), null, paymentMethod.createResponseHandler(callback));
      return paymentMethod;
    };
    function PaymentMethod(attributes) {
      this.attributes = attributes != null ? attributes : {};
      if (config.sandbox) {
        extend(this.attributes, {
          sandbox: true
        });
      }
      this.isNew = this.attributes.payment_method_token != null ? false : true;
      this.errors = {};
      this.messages = {};
      this.createAttrAliases();
    }
    PaymentMethod.prototype.retain = function(callback) {
      return post(this.pathFor('retain'), null, this.createResponseHandler(callback));
    };
    PaymentMethod.prototype.redact = function(callback) {
      return post(this.pathFor('redact'), null, this.createResponseHandler(callback));
    };
    PaymentMethod.prototype.save = function(callback) {
      if (this.isNew) {
        return post(this.pathFor('create'), {
          payment_method: this.sanitizedAttributes()
        }, this.createResponseHandler(__bind(function(err, pm) {
          this.isNew = false;
          return typeof callback === "function" ? callback(err, pm) : void 0;
        }, this)));
      } else {
        return put(this.pathFor('update'), {
          payment_method: this.sanitizedAttributes()
        }, this.createResponseHandler(callback));
      }
    };
    PaymentMethod.prototype.hasErrors = function() {
      return !isEmptyObject(this.errors);
    };
    PaymentMethod.prototype.sanitizedAttributes = function() {
      var attr, key, val, _ref3;
      attr = {};
      _ref3 = this.attributes;
      for (key in _ref3) {
        val = _ref3[key];
        if (KNOWN_ATTRIBUTES.indexOf(key) > -1) {
          attr[key] = val;
        }
      }
      return attr;
    };
    PaymentMethod.prototype.createResponseHandler = function(callback) {
      return __bind(function(err, response) {
        if (err) {
          this.attributes.success = false;
          if (response.error != null) {
            this.updateAttributes(response.error);
          }
        } else {
          if (response.payment_method != null) {
            this.updateAttributes(response.payment_method);
          }
        }
        this.processResponseMessages(response);
        return typeof callback === "function" ? callback(err, this) : void 0;
      }, this);
    };
    PaymentMethod.prototype.pathFor = function(method) {
      var root;
      root = 'payment_methods';
      switch (method) {
        case 'create':
          return root + '.json';
        case 'update':
          return root + '/' + this.token + '.json';
        case 'show':
          return root + '/' + this.token + '.xml';
        default:
          return root + '/' + this.token + '/' + method + '.xml';
      }
    };
    PaymentMethod.prototype.updateAttributes = function(attributes) {
      var prop, _results;
      extend(this.attributes, attributes);
      _results = [];
      for (prop in this.attributes) {
        if (!(prop in this)) {
          _results.push(this.defineAttrAccessor(prop));
        }
      }
      return _results;
    };
    PaymentMethod.prototype.defineAttrAccessor = function(prop) {
      if (!this.__lookupGetter__(camelize(prop))) {
        this.defineAttrGetter(prop);
      }
      if (!(this.__lookupSetter__(camelize(prop)) || KNOWN_ATTRIBUTES.indexOf(prop) === -1)) {
        return this.defineAttrSetter(prop);
      }
    };
    PaymentMethod.prototype.defineAttrGetter = function(prop) {
      return this.__defineGetter__(camelize(prop), function() {
        return this.attributes[prop];
      });
    };
    PaymentMethod.prototype.defineAttrSetter = function(prop) {
      return this.__defineSetter__(camelize(prop), function(value) {
        return this.attributes[prop] = value;
      });
    };
    PaymentMethod.prototype.extractMessagesFromResponse = function(response) {
      var extr, m, messages;
      messages = [];
      extr = function(hash) {
        var key, value, _results;
        _results = [];
        for (key in hash) {
          if (!__hasProp.call(hash, key)) continue;
          value = hash[key];
          _results.push(key === 'messages' ? messages = messages.concat(value) : typeof value === 'object' ? extr(value) : void 0);
        }
        return _results;
      };
      extr(response);
      return messages = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = messages.length; _i < _len; _i++) {
          m = messages[_i];
          _results.push(m.message ? m.message : m);
        }
        return _results;
      })();
    };
    PaymentMethod.prototype.processResponseMessages = function(response) {
      var m, message, messages, order, _i, _len, _results;
      messages = this.extractMessagesFromResponse(response);
      this.messages = {};
      this.errors = {};
      order = ['is_blank', 'not_numeric', 'too_short', 'too_long', 'failed_checksum'];
      messages = messages.sort(function(a, b) {
        a = order.indexOf(a.key);
        b = order.indexOf(b.key);
        if (a === -1) {
          a = 0;
        }
        if (b === -1) {
          b = 0;
        }
        if (a < b) {
          return -1;
        } else if (a > b) {
          return 1;
        } else {
          return 0;
        }
      });
      _results = [];
      for (_i = 0, _len = messages.length; _i < _len; _i++) {
        message = messages[_i];
        m = new Message(message.subclass, message.context, message.key, message.$t);
        if (message.context === '') {
          message.context = 'system.general';
        }
        _results.push(message.subclass === 'error' ? message.context in this.errors ? this.errors[message.context].push(m) : this.errors[message.context] = [m] : message.context in this.messages ? this.messages[message.context].push(m) : this.messages[message.context] = [m]);
      }
      return _results;
    };
    PaymentMethod.prototype.createAttrAliases = function() {
      this.__defineGetter__('token', function() {
        return this.attributes.payment_method_token;
      });
      return this.__defineGetter__('customJsonData', function() {
        var data;
        data = {};
        if (this.attributes.custom != null) {
          try {
            data = JSON.parse(this.attributes.custom);
          } catch (error) {
            data = {};
          }
        }
        return data;
      });
    };
    return PaymentMethod;
  })();
  module.exports = {
    create: PaymentMethod.create,
    find: PaymentMethod.find
  };
}).call(this);
