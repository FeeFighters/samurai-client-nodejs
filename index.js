/**
 * Samurai - main module
 * Copyright (c)2011, by FeeFighters <samurai@feefighters.com>
 * Licensed under MIT license (see LICENSE)
 */

var samurai = require('./lib/samurai');
var transaction = require('./lib/transaction');
var config = require('./lib/config');

exports.configure = config.configure;
exports.option = config.option;
exports.Card = samurai.Card;
exports.Transaction = transaction.Transaction;
