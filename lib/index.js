(function() {
  var Connection, Message, PaymentMethod, Processor, Transaction;
  Connection = require('./connection');
  PaymentMethod = require('./payment_method');
  Transaction = require('./transaction');
  Processor = require('./processor');
  Message = require('./message');
  module.exports = {
    Connection: Connection,
    PaymentMethod: PaymentMethod,
    Transaction: Transaction,
    Processor: Processor,
    Message: Message,
    setupSite: Connection.setup
  };
}).call(this);
