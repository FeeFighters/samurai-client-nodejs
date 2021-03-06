(function() {
  var Message, Transaction, camelize, extend, get, isEmptyObject, post, put, _ref, _ref2;
  var __hasProp = Object.prototype.hasOwnProperty;

  Message = require('./message');

  _ref = require('./helpers'), extend = _ref.extend, camelize = _ref.camelize, isEmptyObject = _ref.isEmptyObject;

  _ref2 = require('./connection'), get = _ref2.get, post = _ref2.post, put = _ref2.put;

  Transaction = (function() {
    var KNOWN_ATTRIBUTES;

    KNOWN_ATTRIBUTES = ['amount', 'type', 'payment_method_token', 'currency_code', 'description', 'custom', 'customer_reference', 'billing_reference'];

    Transaction.find = function(referenceId, callback) {
      var transaction;
      transaction = new Transaction({
        reference_id: referenceId
      });
      return get(transaction.pathFor('show'), null, transaction.createResponseHandler(callback));
    };

    function Transaction(attributes) {
      this.attributes = attributes != null ? attributes : {};
      this.attributes = extend({}, this.attributes);
      this.errors = {};
      this.messages = {};
      this.createAttrAliases();
    }

    Transaction.prototype.capture = function(amount, options, callback) {
      if (options == null) options = {};
      if (typeof amount === 'function') {
        callback = amount;
        amount = this.attributes.amount;
      } else {
        if (amount == null) amount = this.attributes.amount;
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
      if (options == null) options = {};
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      return post(this.pathFor('void'), options, this.createResponseHandler(callback));
    };

    Transaction.prototype.credit = function(amount, options, callback) {
      if (options == null) options = {};
      if (typeof amount === 'function') {
        callback = amount;
        amount = this.attributes.amount;
      } else {
        if (amount == null) amount = this.attributes.amount;
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
      if (options == null) options = {};
      if (typeof amount === 'function') {
        callback = amount;
        amount = this.attributes.amount;
      } else {
        if (amount == null) amount = this.attributes.amount;
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

    Transaction.prototype.hasErrors = function() {
      return !isEmptyObject(this.errors);
    };

    Transaction.prototype.createResponseHandler = function(callback) {
      var _this = this;
      return function(err, response) {
        var _ref3;
        if (err) {
          if ((response != null ? response.error : void 0) != null) {
            _this.updateAttributes(response.error);
          }
          if ((_ref3 = _this.attributes.processor_response) != null) {
            _ref3.success = false;
          }
        } else {
          if ((response != null ? response.transaction : void 0) != null) {
            _this.updateAttributes(response.transaction);
          }
        }
        _this.processResponseMessages(response);
        return typeof callback === "function" ? callback(err, _this) : void 0;
      };
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
        if (!(prop in this)) _results.push(this.defineAttrAccessor(prop));
      }
      return _results;
    };

    Transaction.prototype.defineAttrAccessor = function(prop) {
      if (!this.__lookupGetter__(camelize(prop))) this.defineAttrGetter(prop);
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
          if (key === 'messages') {
            _results.push(messages = messages.concat(value));
          } else {
            if (typeof value === 'object') {
              _results.push(extr(value));
            } else {
              _results.push(void 0);
            }
          }
        }
        return _results;
      };
      extr(response);
      return messages = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = messages.length; _i < _len; _i++) {
          m = messages[_i];
          if (m.message) {
            _results.push(m.message);
          } else {
            _results.push(m);
          }
        }
        return _results;
      })();
    };

    Transaction.prototype.processResponseMessages = function(response) {
      var m, message, messages, order, _i, _len, _results;
      messages = this.extractMessagesFromResponse(response);
      this.messages = {};
      this.errors = {};
      order = ['is_blank', 'not_numeric', 'too_short', 'too_long', 'failed_checksum'];
      messages = messages.sort(function(a, b) {
        a = order.indexOf(a.key);
        b = order.indexOf(b.key);
        if (a === -1) a = 0;
        if (b === -1) b = 0;
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
        if (message.context === '') message.context = 'system.general';
        if (message.subclass === 'error') {
          if (message.context in this.errors) {
            _results.push(this.errors[message.context].push(m));
          } else {
            _results.push(this.errors[message.context] = [m]);
          }
        } else {
          if (message.context in this.messages) {
            _results.push(this.messages[message.context].push(m));
          } else {
            _results.push(this.messages[message.context] = [m]);
          }
        }
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
        if (messages && messages[0]) return messages[0].key;
      });
      return this.__defineGetter__('cvvResultCode', function() {
        var messages;
        messages = this.messages['processor.cvv_result_code'] || this.messages['gateway.cvv_result_code'];
        if (messages && messages[0]) return messages[0].key;
      });
    };

    return Transaction;

  })();

  module.exports = Transaction;

}).call(this);
