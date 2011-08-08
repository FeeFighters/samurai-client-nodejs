/**
 * Samurai - unit tests for configuration module
 * Copyright (c)2011, by FeeFighters <samurai@feefighters.com>
 * Licensed under MIT license (see LICENSE)
 */

var config = require('../lib/config');
var helpers = require('./helpers');
var assert = require('assert');
var test = exports;
var testCase = require('nodeunit').testCase;

// Set up fixtures
var testKeyBases = ['key1', 'key2', 'key3'];
var testKeys = [];
var badKeys = ['bogus', 'foo', '123'];

// Generate some dummy keys
testKeyBases.forEach(function(base) {
  testKeys.push(helpers.generateKey(base));
});

// START TESTING

exports.config = testCase({

  initialState: function(test) {
    test.expect(10);
    test.equal(config.option('merchantKey'), '');
    test.equal(config.option('merchantPassword'), '');
    test.equal(config.option('processorToken'), '');
    test.equal(config.option('currency'), 'USD');
    test.equal(config.option('enabled'), true);
    test.equal(config.option('debug'), false);
    test.equal(config.option('sandbox'), false);
    test.isNotEmpty(config.option('allowedCurrencies'));
    test.contains(config.option('allowedCurrencies'), 'USD');
    test.equal(config.option('allowMultipleSetOption'), false);
    test.done();
  },

  configurationRequiresAllThreeKeys: function(test) {
    test.expect(4);

    test.throws(function() {
      config.configure({});
    });

    test.throws(function() {
      config.configure({
        merchantPassword: testKeys[1],
        processorToken: testKeys[2]
      });
    });

    test.throws(function() {
      config.configure({
        merchantKey: testKeys[0],
        processorToken: testKeys[2]
      });
    });

    test.throws(function() {
      config.configure({
        merchantKey: testKeys[0],
        merchantPassword: testKeys[1]
      });
    });

    test.done();
  },

  configurationFailsWithInvalidLookingKeys: function(test) {
    test.expect(3);

    test.throws(function() {
      config.configure({
        merchantKey: testKeys[0],
        merchantPassword: testKeys[1],
        processorToken: badKeys[0]
      });
    });

    test.throws(function() {
      config.configure({
        merchantKey: testKeys[0],
        merchantPassword: badKeys[0],
        processorToken: testKeys[1]
      });
    });

    test.throws(function() {
      config.configure({
        merchantKey: badKeys[0],
        merchantPassword: testKeys[0],
        processorToken: testKeys[1]
      });
    });

    test.done();
  },

  properConfigurationModifiesSettingsCorrectly: function(test) {
    test.expect(3);
    config.configure({
      merchantKey: testKeys[0],
      merchantPassword: testKeys[1],
      processorToken: testKeys[2],
      allowMultipleSetOption: true // to prevent locking up settings
    });

    test.equal(config.option('merchantKey'), testKeys[0]);
    test.equal(config.option('merchantPassword'), testKeys[1]);
    test.equal(config.option('processorToken'), testKeys[2]);
    test.done();
  },

  settingIndividualConfigurationOptions: function(test) {
    test.expect(16);

    config.option('merchantKey', testKeys[0]);
    test.equal(config.option('merchantKey'), testKeys[0]);

    config.option('merchantPassword', testKeys[1]);
    test.equal(config.option('merchantPassword'), testKeys[1]);

    config.option('processorToken', testKeys[2]);
    test.equal(config.option('processorToken'), testKeys[2]);

    config.option('enabled', false);
    config.option('enabled', true);
    test.equal(config.option('enabled'), true);

    config.option('enabled', false);
    config.option('enabled', 2); // truthy
    test.equal(config.option('enabled'), true);

    config.option('debug', false);
    config.option('debug', true);
    test.equal(config.option('debug'), true);

    config.option('debug', false);
    config.option('debug', 'yes'); // truthy
    test.equal(config.option('debug'), true);
    config.option('debug', false);

    config.option('currency', 'USD');
    config.option('currency', 'JPY');
    test.equal(config.option('currency'), 'JPY');

    config.option('sandbox', false);
    config.option('sandbox', 'yes'); // truthy
    test.equal(config.option('sandbox'), true);

    config.option('allowedCurrencies', ['GBP']);
    test.contains(config.option('allowedCurrencies'), 'GBP');
    test.contains(config.option('allowedCurrencies'), 'JPY'); // includes default

    config.option('allowedCurrencies', []);
    test.isNotEmpty(config.option('allowedCurrencies'));
    test.contains(config.option('allowedCurrencies'), 'JPY');

    test.throws(function() {
      config.option('merchantKey', badKeys[0]);
    }, 'Not valid merchantKey');

    test.throws(function() {
      config.option('merchantPassword', badKeys[0]);
    }, 'Not valid merchantPassword');

    test.throws(function() {
      config.option('processorToken', badKeys[0]);
    }, 'Not valid processorToken');

    test.done();
  }

});
