/**
 * Samurai - unit tests for check module
 * Copyright (c)2011, by FeeFighters <samurai@feefighters.com>
 * Licensed under MIT license (see LICENSE)
 *
 * Cred card numbers used as fixtures come from these URI:
 * https://www.paypalobjects.com/en_US/vhelp/paypalmanager_help/credit_card_numbers.htm
 *
 * All card numbers are test numbers, and cannot be used to make real-life 
 * purchases. They are only useful for testing.
 */

var check = require('../lib/check');
var assert = require('assert');
var helpers = require('./helpers');
var testCase = require('nodeunit').testCase;

var validCardNos = {
  '378282246310005': 'American Express',
  '371449635398431': 'American Express',
  '378734493671000': 'American Express',
  '5610591081018250': 'Unknown', // Australian Bank
  '30569309025904': 'Diners Club',
  '38520000023237': 'Diners Club',
  '6011111111111117': 'Discover',
  '6011000990139424': 'Discover',
  '3530111333300000': 'JCB',
  '3566002020360505': 'JCB',
  '5555555555554444': 'MasterCard',
  '5105105105105100': 'MasterCard',
  '4111111111111111': 'Visa',
  '4012888888881881': 'Visa',
  '4222222222222': 'Visa'
};

exports.check = testCase({

  issuerCheck: function(test) {
    test.expect(15);
    Object.keys(validCardNos).forEach(function(card) {
      test.equal(check.getIssuer(card), validCardNos[card]);
    });
    test.done();
  },

  issuerCheckWithFullDetails: function(test) {
    test.expect(30);
    Object.keys(validCardNos).forEach(function(card) {
      var issuerDetails = check.getIssuer(card, true);
      issuerDetails[0] = validCardNos[card];
      test.isInstanceOf(issuerDetails[1], RegExp);
      test.isInstanceOf(issuerDetails[2], RegExp);
    });
    test.done();
  },

  mod10test: function(test) {
    test.expect(15);
    // All test cards should pass (they are all valid numbers)
    Object.keys(validCardNos).forEach(function(card) {
      test.equal(check.mod10check(card), card);
    });
    test.done();
  },

  cscCheckUsingAmexAndNonAmexCard: function(test) {
    // MasterCard
    test.ok(check.cscCheck('5555555555554444', '111'));
    test.notOk(check.cscCheck('5555555555554444', '11'));
    test.notOk(check.cscCheck('5555555555554444', '1111'));
    test.notOk(check.cscCheck('5555555555554444', 'foo'));

    // Amex
    test.notOk(check.cscCheck('378282246310005', '111'));
    test.ok(check.cscCheck('378282246310005', '1111'));
    test.notOk(check.cscCheck('378282246310005', '11111'));
    test.notOk(check.cscCheck('378282246310005', 'foo'));

    test.done();
  }

});
