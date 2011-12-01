(function() {
  var Message, Transaction, camelize, extend, get, post, put, _ref, _ref2;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty;
  Message = require('./message');
  _ref = require('./helpers'), extend = _ref.extend, camelize = _ref.camelize;
  _ref2 = require('./connection'), get = _ref2.get, post = _ref2.post, put = _ref2.put;
  Transaction = (function() {
    var KNOWN_ATTRIBUTES;
    KNOWN_ATTRIBUTES = ['amount', 'type', 'payment_method_token', 'currency_code', 'descriptor', 'custom', 'customer_reference', 'billing_reference'];
    Transaction.find = function(referenceId, callback) {
      var transaction;
      transaction = new Transaction({
        reference_id: referenceId
      });
      return get(transaction.pathFor('show'), null, function(err, response) {
        transaction.updateAttributes(response.transaction);
        return typeof callback === "function" ? callback(err, transaction) : void 0;
      });
    };
    function Transaction(attributes) {
      this.attributes = attributes != null ? attributes : {};
      this.errors = {};
      this.messages = {};
      this.createAttrAliases();
    }
    Transaction.prototype.capture = function(amount, options, callback) {
      if (options == null) {
        options = {};
      }
      if (typeof amount === 'function') {
        callback = amount;
        amount = this.attributes.amount;
      } else {
        if (amount == null) {
          amount = this.attributes.amount;
        }
      }
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      extend(options, {
        amount: amount
      });
      return post(this.pathFor('capture'), options, this.createResponseHandler(callback));
    };
    Transaction.prototype["void"] = function(options, callback) {
      if (options == null) {
        options = {};
      }
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      return post(this.pathFor('void'), options, this.createResponseHandler(callback));
    };
    Transaction.prototype.credit = function(amount, options, callback) {
      if (options == null) {
        options = {};
      }
      if (typeof amount === 'function') {
        callback = amount;
        amount = this.attributes.amount;
      } else {
        if (amount == null) {
          amount = this.attributes.amount;
        }
      }
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      extend(options, {
        amount: amount
      });
      return post(this.pathFor('credit'), options, this.createResponseHandler(callback));
    };
    Transaction.prototype.reverse = function(amount, options, callback) {
      if (options == null) {
        options = {};
      }
      if (typeof amount === 'function') {
        callback = amount;
        amount = this.attributes.amount;
      } else {
        if (amount == null) {
          amount = this.attributes.amount;
        }
      }
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      extend(options, {
        amount: amount
      });
      return post(this.pathFor('reverse'), options, this.createResponseHandler(callback));
    };
    Transaction.prototype.isSuccess = function() {
      var _ref3;
      return ((_ref3 = this.attributes.processor_response) != null ? _ref3.success : void 0) === true;
    };
    Transaction.prototype.isFailed = function() {
      return !this.isSuccess();
    };
    Transaction.prototype.createResponseHandler = function(callback) {
      return __bind(function(err, response) {
        var _ref3;
        if (err) {
          if ((response != null ? response.error : void 0) != null) {
            this.updateAttributes(response.error);
          }
          if ((_ref3 = this.attributes.processor_response) != null) {
            _ref3.success = false;
          }
        } else {
          if ((response != null ? response.transaction : void 0) != null) {
            this.updateAttributes(response.transaction);
          }
        }
        this.processResponseMessages(response);
        return typeof callback === "function" ? callback(err, this) : void 0;
      }, this);
    };
    Transaction.prototype.pathFor = function(method) {
      var root;
      root = 'transactions';
      switch (method) {
        case 'show':
          return root + '/' + this.attributes.reference_id + '.xml';
        default:
          return root + '/' + this.token + '/' + method + '.xml';
      }
    };
    Transaction.prototype.updateAttributes = function(attributes) {
      var attr, prop, value, _results;
      for (attr in attributes) {
        value = attributes[attr];
        if (!(attr in this.attributes && value === '')) {
          this.attributes[attr] = value;
        }
      }
      _results = [];
      for (prop in this.attributes) {
        if (!(prop in this)) {
          _results.push(this.defineAttrAccessor(prop));
        }
      }
      return _results;
    };
    Transaction.prototype.defineAttrAccessor = function(prop) {
      if (!this.__lookupGetter__(camelize(prop))) {
        this.defineAttrGetter(prop);
      }
      if (!(this.__lookupSetter__(camelize(prop)) || KNOWN_ATTRIBUTES.indexOf(prop) === -1)) {
        return this.defineAttrSetter(prop);
      }
    };
    Transaction.prototype.defineAttrGetter = function(prop) {
      return this.__defineGetter__(camelize(prop), function() {
        return this.attributes[prop];
      });
    };
    Transaction.prototype.defineAttrSetter = function(prop) {
      return this.__defineSetter__(camelize(prop), function(value) {
        return this.attributes[prop] = value;
      });
    };
    Transaction.prototype.extractMessagesFromResponse = function(response) {
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
    Transaction.prototype.processResponseMessages = function(response) {
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
    Transaction.prototype.createAttrAliases = function() {
      this.__defineGetter__('token', function() {
        return this.attributes.transaction_token;
      });
      this.__defineGetter__('avsResultCode', function() {
        var messages;
        messages = this.messages['processor.avs_result_code'] || this.messages['gateway.avs_result_code'];
        if (messages && messages[0]) {
          return messages[0].key;
        }
      });
      return this.__defineGetter__('cvvResultCode', function() {
        var messages;
        messages = this.messages['processor.cvv_result_code'] || this.messages['gateway.cvv_result_code'];
        if (messages && messages[0]) {
          return messages[0].key;
        }
      });
    };
    return Transaction;
  })();
  module.exports = Transaction;
}).call(this);
