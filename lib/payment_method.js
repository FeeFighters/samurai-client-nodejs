(function() {
  var Message, PaymentMethod, extend, get, post, put, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty;
  extend = require('./helpers').extend;
  _ref = require('./connection'), get = _ref.get, post = _ref.post, put = _ref.put;
  Message = require('./message');
  PaymentMethod = (function() {
    var KNOWN_ATTRIBUTES;
    KNOWN_ATTRIBUTES = ['first_name', 'last_name', 'address_1', 'address_2', 'city', 'state', 'zip', 'card_number', 'cvv', 'expiry_month', 'expiry_year', 'custom'];
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
      return get(paymentMethod.pathFor('show'), null, function(err, response) {
        paymentMethod.updateAttributes(response.payment_method);
        return typeof callback === "function" ? callback(err, paymentMethod) : void 0;
      });
    };
    function PaymentMethod(attributes) {
      this.attributes = attributes != null ? attributes : {};
      this.isNew = this.attributes.payment_method_token != null ? false : true;
      this.errors = {};
      this.messages = {};
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
    PaymentMethod.prototype.sanitizedAttributes = function() {
      var attr, key, val, _ref2;
      attr = {};
      _ref2 = this.attributes;
      for (key in _ref2) {
        val = _ref2[key];
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
          return root + '/' + this.token() + '.json';
        case 'show':
          return root + '/' + this.token() + '.xml';
        default:
          return root + '/' + this.token() + '/' + method + '.xml';
      }
    };
    PaymentMethod.prototype.updateAttributes = function(attributes) {
      return extend(this.attributes, attributes);
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
      var m, message, messages, _i, _len, _results;
      messages = this.extractMessagesFromResponse(response);
      this.messages = {};
      this.errors = {};
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
    PaymentMethod.prototype.token = function() {
      return this.attributes.payment_method_token;
    };
    PaymentMethod.prototype.customJSONData = function() {
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
    };
    return PaymentMethod;
  })();
  module.exports = {
    create: PaymentMethod.create,
    find: PaymentMethod.find
  };
}).call(this);
