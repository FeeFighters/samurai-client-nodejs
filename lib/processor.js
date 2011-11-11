(function() {
  var Processor, Transaction, config, extend, get, post, put, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  extend = require('./helpers').extend;
  _ref = require('./connection'), get = _ref.get, post = _ref.post, put = _ref.put, config = _ref.config;
  Transaction = require('./transaction');
  Processor = (function() {
    Processor.theProcessor = function() {
      var theProcessor;
      theProcessor = new Processor(config.processor_token);
      this.theProcessor = function() {
        return theProcessor;
      };
      return theProcessor;
    };
    Processor.purchase = function() {
      return this.theProcessor().purchase.apply(this.theProcessor(), arguments);
    };
    Processor.authorize = function() {
      return this.theProcessor().authorize.apply(this.theProcessor(), arguments);
    };
    Processor.find = function(processorToken) {
      this.processorToken = processorToken;
      return new Processor(this.processorToken);
    };
    function Processor(processorToken) {
      this.processorToken = processorToken;
    }
    Processor.prototype.purchase = function(paymentMethodToken, amount, options, callback) {
      if (options == null) {
        options = {};
      }
      extend(options, {
        payment_method_token: paymentMethodToken,
        amount: amount
      });
      return post(this.pathFor('purchase'), this.prepareTransactionData(options), this.createResponseHandler(callback));
    };
    Processor.prototype.authorize = function(paymentMethodToken, amount, options, callback) {
      if (options == null) {
        options = {};
      }
      extend(options, {
        payment_method_token: paymentMethodToken,
        amount: amount
      });
      return post(this.pathFor('authorize'), this.prepareTransactionData(options), this.createResponseHandler(callback));
    };
    Processor.prototype.createResponseHandler = function(callback) {
      return __bind(function(err, response) {
        var transaction, _ref2, _ref3;
        transaction = new Transaction();
        if (err) {
          if ((_ref2 = transaction.attributes) != null) {
            if ((_ref3 = _ref2.processor_response) != null) {
              _ref3.success = false;
            }
          }
        } else {
          transaction.updateAttributes(response.transaction);
        }
        transaction.processResponseMessages(response);
        return typeof callback === "function" ? callback(err, transaction) : void 0;
      }, this);
    };
    Processor.prototype.pathFor = function(method) {
      var root;
      root = 'processors/' + this.processorToken + '/';
      switch (method) {
        case 'purchase':
          return root + 'purchase.xml';
        case 'authorize':
          return root + 'authorize.xml';
      }
    };
    Processor.prototype.prepareTransactionData = function(options) {
      return {
        transaction: options
      };
    };
    return Processor;
  })();
  module.exports = Processor;
}).call(this);
