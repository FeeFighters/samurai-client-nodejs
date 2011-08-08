/**
 * Samurai - unit tests for the main Samurai module
 * Copyright (c)2011, by FeeFighters.
 * Licensed under MIT license (see LICENSE)
 */
var sys = require('sys');
var assert = require('assert');
var helpers = require('./helpers');
var getAdjustedDateparts = helpers.getAdjustedDateparts;
var getRandomAmount = helpers.getRandomAmount;
var samurai = require('../index.js');
var messages = require('../lib/messages');
var testCase = require('nodeunit').testCase;
var test = exports;

var testNonExpiredDate = getAdjustedDateparts(12); // One year in future
var testExpiredDate = getAdjustedDateparts(-12); // One year ago
var testSettings = require('./config');

var testCard = {
  number: '5555555555554444', // MasterCard
  csc: '111',
  year: testNonExpiredDate[0].toString(),
  month: testNonExpiredDate[1].toString(),
  firstName: 'Foo',
  lastName: 'Bar',
  address1: '221 Foo st',
  address2: '', // blank
  city: '', // blank
  state: '', // blank
  zip: '99561'
};

var sandboxValidCard = {
  number: '4111-1111-1111-1111',
  csc: '123',
  year: testNonExpiredDate[0].toString(),
  month: testNonExpiredDate[1].toString()
  // No other extra data, this is only for testing transactions
};

var sandboxDeclinedCard = {
  number: '4222222222222',
  csc: '123',
  year: testNonExpiredDate[0].toString(),
  month: testNonExpiredDate[1].toString()
  // No other extra data, this is only for testing transactions
};

var bogusCard = {
  number: '2420318231',
  csc: '14111',
  year: testExpiredDate[0].toString(),
  month: testExpiredDate[1].toString()
};

//
// Before All
//
samurai.option('sandbox', false);
samurai.option('debug', true);
samurai.option('currency', 'USD');
samurai.option('allowedCurrencies', ['USD']);
samurai.configure(testSettings);


exports.samurai = testCase({

  setUp: function(callback) {
    callback();
  },

  configureAndLockConfiguration: function(test) {
    test.expect(2);
    testSettings.allowMultipleSetOption = false;
    samurai.configure(testSettings);
    test.throws(function() {
      samurai.configure(testSettings);
    });
    test.throws(function() {
      samurai.option('debug', false);
    });
    test.done();
  },

  samuraiModuleHasCardConstructor: function(test) {
    test.expect(2);
    test.hasProperty(samurai, 'Card');
    test.equal(typeof samurai.Card, 'function');
    test.done();
  },

  creatingANewCard: function(test) {
    test.expect(22);

    var card = new samurai.Card(testCard);

    test.hasProperty( card, 'number'  );
    test.equal( card.number, testCard.number );

    test.hasProperty( card, 'issuer'  );
    test.equal( card.issuer, 'MasterCard' );

    test.hasProperty( card, 'year'  );
    test.equal( card.year, testNonExpiredDate[0] );

    test.hasProperty( card, 'month'  );
    test.equal( card.month, testNonExpiredDate[1] );

    test.hasProperty( card, 'firstName'  );
    test.equal( card.firstName, 'Foo' );

    test.hasProperty( card, 'lastName'  );
    test.equal( card.lastName, 'Bar' );

    test.hasProperty( card, 'address1'  );
    test.equal( card.address1, '221 Foo st' );

    test.hasProperty( card, 'address2'  );
    test.equal( card.address2, '' );

    test.hasProperty( card, 'city'  );
    test.equal( card.city, '' );

    test.hasProperty( card, 'state'  );
    test.equal( card.state, '' );

    test.hasProperty( card, 'zip'  );
    test.equal( card.zip, '99561' );

    test.done();
  },

  creatingABogusCard: function(test) {
    test.expect(6);

    var card = new samurai.Card(bogusCard);

    test.hasProperty( card, 'number'  );
    test.equal( card.number, bogusCard.number );

    test.hasProperty( card, 'issuer'  );
    test.equal( card.issuer, 'Unknown' );

    test.hasProperty( card, 'csc'  );
    test.equal( card.csc, '14111' );

    test.done();
  },

  cardNumberShouldBeStrippedOfNonDigitElements: function(test) {
    test.expect(1);
    var card = new samurai.Card({
      number: '4111-1111-1111-1111',
      csc: '123'
    });
    test.equal( card.number, '4111111111111111');
    test.done();
  },

  creatingCardWithoutCardNumberOrCSCThrows: function(test) {
    test.expect(3);

    test.throws(function() {
      card = new samurai.Card({});
    }, 'Card number is required');

    test.throws(function() {
      card = new samurai.Card({
        number: testCard.number
      });
    }, 'CSC is required');

    test.throws(function() {
      card = new samurai.Card({
        csc: testCard.csc
      });
    }, 'Card number is required');

    test.done();
  },

  convert2DigitOr1DigitYearto4Digits: function(test) {
    test.expect(2);

    var card = new samurai.Card({
      number: testCard.number,
      csc: testCard.csc,
      year: '2' // Should convert to 2nd year of this decade
    });
    test.equal( card.year, 2012);

    card = new samurai.Card({
      number: testCard.number,
      csc: testCard.csc,
      year: '15' // Should convert to year 15 of current century
    });
    test.equal( card.year, 2015);

    test.done();
  },

  yearIsNormalizedWithSettingYearProperty: function(test) {
    test.expect(1);

    var card = new samurai.Card(testCard);
    card.year = '3';
    test.equal( card.year, 2013);

    test.done();
  },

  cannotSetInvalidMonth: function(test) {
    test.expect(3);

    var card = new samurai.Card({
      number: testCard.number,
      csc: testCard.csc,
      month: '123'
    });
    test.isUndefined(card.month);

    card.month = 'foo';
    test.isUndefined(card.month);

    card.month = '13';
    test.isUndefined(card.month);

    test.done();
  },

  cardValidation: function(test) {
    test.expect(2);

    var card = new samurai.Card(testCard);
    test.equal( card.isValid(), true);

    card = new samurai.Card(bogusCard);
    test.equal( card.isValid(), false);

    test.done();
  },

  cardExpirationCheck: function(test) {
    test.expect(2);

    var card = new samurai.Card(testCard);
    test.equal( card.isExpired(), false);

    card = new samurai.Card(bogusCard);
    test.equal( card.isExpired(), true);

    test.done();
  },

  createMethodSetsAToken: function(test) {
    test.expect(2);
    var card = new samurai.Card(testCard);

    card.create(function(err) {
      test.isUndefined(err);
      test.ok(card.token =~ /^[0-9a-f]{24}$/);
      test.done();
    });
  },

  createdCardCanLoadPaymentMethodData: function(test) {
    test.expect(17);
    var card = new samurai.Card(testCard);
    var card1, token;

    card.custom = {test: 'custom'};

    test.throws(function() {
      card.load();
    }, 'Cannot load payment method without token');

    card.create(function(err) {
      token = card.token;
      card1 = new samurai.Card({token: token});
      card1.load(function(err) {
        test.isUndefined(err);
        test.hasProperty(card1, 'method');
        test.hasProperty(   card1.method, 'createdAt'  );
        test.isInstanceOf(  card1.method.createdAt, Date );
        test.hasProperty(   card1.method, 'updatedAt'  );
        test.isInstanceOf(  card1.method.updatedAt, Date );
        test.hasProperty(   card1.method, 'retained'  );
        test.equal(         card1.method.retained, false  );
        test.hasProperty(   card1.method, 'redacted'  );
        test.equal(         card1.method.redacted, false  );
        test.equal(         card1.firstName, testCard.firstName  );
        test.equal(         card1.lastName, testCard.lastName  );
        test.equal(         card1.address1, testCard.address1  );
        test.hasProperty(   card1, 'custom'  );
        test.hasProperty(   card1.custom, 'test'  );
        test.equal(         card1.custom.test, 'custom');
        test.done();
      });
    });
  },

  createABadPaymentMethod: function(test) {
    test.expect(6);
    var card = new samurai.Card(bogusCard);

    function onLoad(err) {
      test.hasProperty(card, 'messages');
      test.hasProperty(card.messages, 'errors');
      test.hasProperty(card.messages.errors, 'number');
      test.contains(card.messages.errors.number, messages.str.en_US.INVALID_NUMBER);
      test.hasProperty(card.messages.errors, 'csc');
      test.contains(card.messages.errors.csc, messages.str.en_US.INVALID_CSC);
      test.done();
    }

    card.create(function(err) {
      card.load(onLoad);
    });
  },

  cardHasDirtyPropertyWhichListsChangedFields: function(test) {
    test.expect(17);

    // Initially, all fields are dirty
    var card = new samurai.Card(testCard);

    test.hasProperty( card, '_dirty'  );
    test.isNotEmpty(  card._dirty );
    test.contains(  card._dirty, 'number' );
    test.contains(  card._dirty, 'csc' );
    test.contains(  card._dirty, 'year' );
    test.contains(  card._dirty, 'month' );
    test.contains(  card._dirty, 'firstName' );
    test.contains(  card._dirty, 'lastName' );
    test.contains(  card._dirty, 'address1' );
    test.contains(  card._dirty, 'zip' );

    card.create(function(err) {
      test.isUndefined(err);
      test.isEmpty(card._dirty);
      card.load(function(err) {
        test.isUndefined(err);
        test.isEmpty(card._dirty);
        card.year = card.year + 1;
        test.contains(card._dirty, 'year');
        card.month = (card.month + 1) % 12;
        test.contains(card._dirty, 'month');
        card.firstName = 'Foom';
        test.contains(card._dirty, 'firstName');
        test.done();
      });
    });
  },

  updatedAModifiedCard: function(test) {
    test.expect(18);

    var card = new samurai.Card(testCard);
    card.create(function(err) {
      test.notEqual(card.city, 'Smallville');
      card.city = 'Smallville';
      card.month = '12';
      test.contains(card._dirty, 'city');
      test.contains(card._dirty, 'month');
      card.update(function(err) {
        test.isEmpty(       card._dirty );
        test.equal(         card.city, 'Smallville' );
        test.equal(         card.month,  12 );
        test.hasProperty(   card, 'method'  );
        test.hasProperty(   card.method, 'createdAt'  );
        test.isInstanceOf(  card.method.createdAt, Date );
        test.hasProperty(   card.method, 'updatedAt'  );
        test.isInstanceOf(  card.method.updatedAt, Date );
        test.hasProperty(   card.method, 'retained'  );
        test.equal(         card.method.retained, false  );
        test.hasProperty(   card.method, 'redacted'  );
        test.equal(         card.method.redacted, false  );
        test.equal(         card.firstName, testCard.firstName  );
        test.equal(         card.lastName, testCard.lastName  );
        test.equal(         card.address1, testCard.address1  );
        test.done();
      });
    });
  },

  retainCard: function(test) {
    test.expect(12);
    var card = new samurai.Card(testCard);

    card.create(function(err) {
      card.retain(function(err) {
        test.hasProperty(   card, 'method' );
        test.hasProperty(   card.method, 'createdAt'  );
        test.isInstanceOf(  card.method.createdAt, Date );
        test.hasProperty(   card.method, 'updatedAt'  );
        test.isInstanceOf(  card.method.updatedAt, Date );
        test.hasProperty(   card.method, 'retained'  );
        test.equal(         card.method.retained, true  );
        test.hasProperty(   card.method, 'redacted'  );
        test.equal(         card.method.redacted, false  );
        test.equal(         card.firstName, testCard.firstName  );
        test.equal(         card.lastName, testCard.lastName  );
        test.equal(         card.address1, testCard.address1  );
        test.done();
      });
    });
  },

  redactCard: function(test) {
    test.expect(4);
    var card = new samurai.Card(testCard);

    card.create(function(err) {
      card.retain(function(err) {
        test.ok(card.method.retained);
        test.notOk(card.method.redacted);
        card.redact(function(err) {
          test.ok(card.method.retained);
          test.ok(card.method.redacted);
          test.done();
        });
      });
    });
  },

  creatingNewTransactionObjectThrowsIfNoType: function(test) {
    test.expect(1);
    var transaction;

    test.throws(function() {
      transaction = new samurai.Transaction({
        type: null,
        data: {amount: getRandomAmount()}
      });
    });

    test.done();
  },

  creatingNewTransactionThrowsWithMissingData: function(test) {
    test.expect(1);
    var transaction;

    test.throws(function() {
      transaction = new samurai.Transaction({
        type: 'purchase',
        data: null
      });
    });

    test.done();
  },

  newTransactionHasAFewExtraProperties: function(test) {
    test.expect(7);

    var transaction = new samurai.Transaction({
      type: 'purchase',
      data: {amount: getRandomAmount()}
    });

    test.hasProperty( transaction, 'type' );
    test.equal(       transaction.type, 'purchase' );
    test.hasProperty( transaction, 'data' );
    test.hasKeys(     transaction.data, ['amount', 'type', 'currency'] );
    test.equal(       transaction.data.type, 'purchase' );
    test.equal(       transaction.data.currency, samurai.option('currency') );
    test.hasProperty( transaction, 'path' );

    test.done();
  },

  simpleTransactionsDoNotSetTypeAndCurrency: function(test) {
    test.expect(2);

    var transaction = new samurai.Transaction({
      type: 'void',
      transactionId: '111111111111111111111111',
      data: {}
    });

    test.hasNoProperty( transaction.data, 'currency' );
    test.hasNoProperty( transaction.data, 'type' );

    test.done();
  },

  executeTransaction: function(test) {
    test.expect(11);
    var transaction;

    function callback(err) {
      test.isUndefined(err);
      test.hasProperty( transaction, 'receipt' );
      test.hasProperty( transaction.receipt, 'success' );
      test.ok(          transaction.receipt.success );
      test.hasProperty( transaction.receipt, 'custom'  );
      test.equal(       transaction.receipt.custom.test, 'custom' );
      test.hasProperty( transaction, 'messages'  );
      test.hasProperty( transaction.messages, 'info' );
      test.hasProperty( transaction.messages.info, 'transaction' );
      test.contains(    transaction.messages.info.transaction, 'Success' );
      test.done();
    }

    transaction = new samurai.Transaction({
      type: 'purchase',
      data: {
        billingReference: Math.floor(Math.random()*100),
        customerReference: '123',
        amount: getRandomAmount(),
        custom: {test: 'custom'}
      }
    });

    // First we need a card
    var card = new samurai.Card(sandboxValidCard);

    card.create(function(err) {
      // We have the token now.
      test.isDefined(  card.token  );
      transaction.process(card, callback);
    });
  },

  executeTransactionWithDeclinedCard: function(test) {
    test.expect(9);
    var transaction;

    function callback(err) {
      test.isUndefined(err);
      test.hasProperty( transaction, 'receipt' );
      test.hasProperty( transaction.receipt, 'success' );
      test.equal(       transaction.receipt.success, false  );
      test.hasProperty( transaction, 'messages'  );
      test.hasProperty( transaction.messages, 'errors'  );
      test.hasProperty( transaction.messages.errors, 'transaction'  );
      test.contains(    transaction.messages.errors.transaction, 'Declined' );
      test.done();
    }

    transaction = new samurai.Transaction({
      type: 'purchase',
      data: {
        billingReference: Math.floor(Math.random()*100),
        customerReference: '123',
        amount: 2  // Declined amount code
      }
    });

    var card = new samurai.Card(sandboxDeclinedCard);

    card.create(function(err) {
      // We have the token now.
      test.isDefined(  card.token  );
      transaction.process(card, callback);
    });
  },

  usingTransactionsWithWrongCurrency: function(test) {
    test.expect(9);
    var transaction;

    function callback(err) {
      test.isDefined(err);
      test.hasProperty( err, 'category' );
      test.equal(       err.category, 'system' );
      test.hasProperty( err, 'message' );
      test.equal(       err.message, 'Currency not allowed'  );
      test.hasProperty( err, 'details' );
      test.equal(       err.details, 'GBP'  );
      test.hasNoProperty( transaction, 'receipt' );
      test.done();
    }

    transaction = new samurai.Transaction({
      type: 'purchase',
      data: {
        amount: getRandomAmount(),
        currency: 'GBP'
      }
    });

    // First we need a card
    var card = new samurai.Card(sandboxValidCard);

    card.create(function(err) {
      // We have the token now.
      test.isDefined(  card.token  );
      transaction.process(card, callback);
    });
  },

  cardWithNoTokenCannotBeUsedForTransaction: function(test) {
    test.expect(6);
    var transaction;

    function callback(err) {
      test.isDefined(err);
      test.hasProperty(   err, 'category' );
      test.equal(         err.category, 'system'  );
      test.hasProperty(   err, 'message' );
      test.equal(         err.message, 'Card has no token'  );
      test.hasNoProperty( transaction, 'receipt' );
      test.done();
    }

    transaction = new samurai.Transaction({
      type: 'purchase',
      data: {
        amount: getRandomAmount(),
        currency: 'USD'
      }
    });

    var card = new samurai.Card(sandboxValidCard);
    transaction.process(card, callback);
  }

});
